set(AARCH64 gcc-arm-8.3-2019.03-x86_64-aarch64-linux-gnu)
set(DOWNLOAD_FROM https://storage.googleapis.com/mirror.tensorflow.org/developer.arm.com/media/Files/downloads/gnu-a/8.3-2019.03/binrel)

if(NOT EXISTS ${CMAKE_SOURCE_DIR}/toolchains/${AARCH64})
    file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/toolchains)
    file(DOWNLOAD ${DOWNLOAD_FROM}/${AARCH64}.tar.xz ${CMAKE_BINARY_DIR}/toolchain.tar.xz SHOW_PROGRESS)
    execute_process(COMMAND
	${CMAKE_COMMAND} -E tar xvf ${CMAKE_BINARY_DIR}/toolchain.tar.xz
	WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/toolchains
    )
    file(REMOVE ${CMAKE_BINARY_DIR}/toolchain.tar.xz)
endif()

set(ARMCC_PREFIX ${CMAKE_SOURCE_DIR}/toolchains/${AARCH64}/bin/aarch64-linux-gnu-)
set(ARMCC_FLAGS "-funsafe-math-optimizations")
set(CMAKE_C_COMPILER ${ARMCC_PREFIX}gcc)
set(CMAKE_CXX_COMPILER ${ARMCC_PREFIX}g++)
set(CMAKE_C_FLAGS ${ARMCC_FLAGS})
set(CMAKE_CXX_FLAGS ${ARMCC_FLAGS})
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)
#set(CMAKE_VERBOSE_MAKEFILE ON)
