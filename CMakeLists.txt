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

# target-dependent preparation
set(NERVES_ARMV6 rpi rpi0)
set(NERVES_ARMV7NEON rpi2 rpi3 rpi3a bbb osd32mp1)
set(NERVES_AARCH64 rpi4)

if("$ENV{MIX_TARGET}" IN_LIST NERVES_ARMV6)
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
  GIT_TAG        v2.8.0
  GIT_PROGRESS   TRUE
  SOURCE_DIR "${CMAKE_SOURCE_DIR}/3rd_party/tensorflow_src"
  SOURCE_SUBDIR tensorflow/lite
)
else()
FetchContent_Declare(tensorflow
  SOURCE_DIR "${CMAKE_SOURCE_DIR}/3rd_party/tensorflow_src"
  SOURCE_SUBDIR tensorflow/lite
)
endif()

FetchContent_MakeAvailable(tensorflow)

# add Nlohmann JSON
if(NOT EXISTS ${CMAKE_SOURCE_DIR}/3rd_party/nlohmann_json)
message("** Download nlohmann_json.")
FetchContent_Declare(nlohmann_json
  GIT_REPOSITORY https://github.com/nlohmann/json.git
  GIT_PROGRESS   TRUE
  SOURCE_DIR "${CMAKE_SOURCE_DIR}/3rd_party/nlohmann_json"
)
else()
FetchContent_Declare(nlohmann_json
  SOURCE_DIR "${CMAKE_SOURCE_DIR}/3rd_party/nlohmann_json"
)
endif()
FetchContent_MakeAvailable(nlohmann_json)

# apply the patch to TensorFlow file set when target is Windows.
IF((${CMAKE_HOST_SYSTEM_NAME} MATCHES "Windows") AND (NOT EXISTS ${CMAKE_SOURCE_DIR}/3rd_party/patched))
  execute_process(
    COMMAND patch --verbos -p1 -i ${CMAKE_SOURCE_DIR}/msys2.patch1
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/3rd_party
  )
  file(TOUCH ${CMAKE_SOURCE_DIR}/3rd_party/patched)
endif()

IF((${CMAKE_HOST_SYSTEM_NAME} MATCHES "Windows") AND (NOT EXISTS ${CMAKE_BINARY_DIR}/patched))
  execute_process(
    COMMAND patch --verbos -p1 -i ${CMAKE_SOURCE_DIR}/msys2.patch2
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  )
  file(TOUCH ${CMAKE_BINARY_DIR}/patched)
endif()

# main
add_executable(tfl_interp
  src/main.cc
  src/tiny_ml.cc
  src/tfl_interp.cc
  src/io_port.cc
  src/nonmaxsuppression.cc
)
target_link_libraries(tfl_interp
  tensorflow-lite
  nlohmann_json
)

install(TARGETS tfl_interp
  RUNTIME
  DESTINATION $ENV{MIX_APP_PATH}/priv
)

install(TARGETS tfl_interp
  RUNTIME
  DESTINATION ${CMAKE_SOURCE_DIR}/priv
)
