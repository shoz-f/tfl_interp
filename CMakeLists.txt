# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

cmake_minimum_required(VERSION 3.18)

set(THIRD_PARTY ${CMAKE_SOURCE_DIR}/3rd_party)
set(TFLITE_ROOTDIR ${THIRD_PARTY}/tensorflow_src)

set(CMAKE_CXX_STANDARD 17)

# target-dependent preparation
set(NERVES_ARMV6 rpi rpi0)
set(NERVES_ARMV7NEON rpi2 rpi3 rpi3a bbb osd32mp1)
set(NERVES_AARCH64 rpi4)

if(MSVC)
    # empty now

elseif("$ENV{MIX_TARGET}" IN_LIST NERVES_ARMV6)
    message("Target is ARMv6")
    message("...donwload toolchain")
    include(toolchain_armv6.cmake)

elseif("$ENV{MIX_TARGET}" IN_LIST NERVES_ARMV7NEON)
    message("Target is ARMv7NEON")
    message("...donwload toolchain")
    include(toolchain_armv7neon.cmake)

elseif("$ENV{MIX_TARGET}" IN_LIST NERVES_AARCH64)
    message("AArch64 has not been testes yet!!!\n...donwload toolchain")
    include(toolchain_aarch64.cmake)
endif()

################################################################################
# project start here
project(tfl_interp CXX)

install(CODE "set(CMAKE_INSTALL_LOCAL_ONLY ON)")

# check requirements
find_package(Patch)
if(NOT Patch_FOUND)
    message(FATAL_ERROR "Patch not found patch command")
endif()

# add external projects
include(FetchContent)
Set(FETCHCONTENT_QUIET FALSE)

# add Tensorflow sources
if(NOT EXISTS ${CMAKE_SOURCE_DIR}/3rd_party/tensorflow_src)
    message("** Download Tensorflow lite etc.")
    FetchContent_Declare(tensorflow
	GIT_REPOSITORY https://github.com/tensorflow/tensorflow.git
	GIT_TAG        v2.12.0
	GIT_PROGRESS   TRUE
	SOURCE_DIR "${THIRD_PARTY}/tensorflow_src"
	SOURCE_SUBDIR tensorflow/lite
	PATCH_COMMAND git apply ${CMAKE_SOURCE_DIR}/tensorflow_2_12_0_lite.patch
    )
else()
    FetchContent_Declare(tensorflow
	SOURCE_DIR "${THIRD_PARTY}/tensorflow_src"
	SOURCE_SUBDIR tensorflow/lite
    )
endif()
FetchContent_MakeAvailable(tensorflow)

# add Nlohmann JSON
set(URL_NLOHMANN_JSON "https://github.com/nlohmann/json/releases/download/v3.7.3/include.zip")
set(NLOHMANN_JSON_ROOTDIR ${THIRD_PARTY}/nlohmann_json)

if(NOT EXISTS ${NLOHMANN_JSON_ROOTDIR})
    message("** Download nlohmann_json.")
    FetchContent_Declare(nlohmann_json
	URL ${URL_NLOHMANN_JSON}
	SOURCE_DIR ${NLOHMANN_JSON_ROOTDIR}
    )
    FetchContent_MakeAvailable(nlohmann_json)
endif()

include_directories(${NLOHMANN_JSON_ROOTDIR}/include)

# custom operations
set(CUSTOM_OPS
    src/custom_ops/max_pool_argmax.cc
    src/custom_ops/max_unpooling.cc
    src/custom_ops/transpose_conv_bias.cc
    )

# main
add_executable(tfl_interp
    src/main.cc
    src/tiny_ml.cc
    src/tfl_interp.cc
    src/io_port.cc
    src/nonmaxsuppression.cc
    src/getopt/getopt.c
    src/getopt/getopt_long.c
    ${CUSTOM_OPS}
)
target_link_libraries(tfl_interp
    tensorflow-lite
)

# installation
install(TARGETS tfl_interp
    RUNTIME
    DESTINATION $ENV{MIX_APP_PATH}/priv
)

install(TARGETS tfl_interp
    RUNTIME
    DESTINATION ${CMAKE_SOURCE_DIR}/priv
)
