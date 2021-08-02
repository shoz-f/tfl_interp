#
# Copyright 2020 The TensorFlow Authors. All Rights Reserved.
#
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

cmake_minimum_required(VERSION 3.16)
project(tfl_interp CXX)

include(FetchContent)
FetchContent_Declare(tensorflow
  GIT_REPOSITORY https://github.com/tensorflow/tensorflow.git
  SOURCE_SUBDIR tensorflow/lite
  SOURCE_DIR "${CMAKE_BINARY_DIR}/tensorflow_src"
)
FetchContent_MakeAvailable(tensorflow)

IF(NOT EXISTS ${CMAKE_BINARY_DIR}/patched)
  execute_process(
    COMMAND patch --verbos -p1 -i msys2.patch
    WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
  )

  file(TOUCH ${CMAKE_BINARY_DIR}/patched)
endif()

add_executable(tfl_interp
  src/tfl_interp.cc
  src/io_port.cc
  src/tfl_nonmaxsuppression.cc
)
target_link_libraries(tfl_interp
  tensorflow-lite
)
