set(ARMV6 arm-rpi-linux-gnueabihf)
set(DOWNLOAD_NAME eb68350c5c8ec1663b7fe52c742ac4271e3217c5)

set(DOWNLOAD_FROM https://github.com/rvagg/rpi-newer-crosstools/archive)

if(NOT EXISTS ${CMAKE_SOURCE_DIR}/toolchains/${ARMV6})
    file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/toolchains)
    file(DOWNLOAD ${DOWNLOAD_FROM}/${DOWNLOAD_NAME}.tar.gz ${CMAKE_BINARY_DIR}/toolchain.tar.gz SHOW_PROGRESS)
    execute_process(COMMAND
	${CMAKE_COMMAND} -E tar xvf ${CMAKE_BINARY_DIR}/toolchain.tar.gz
	WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/toolchains
    )
    file(RENAME ${CMAKE_SOURCE_DIR}/toolchains/rpi-newer-crosstools-${DOWNLOAD_NAME} ${CMAKE_SOURCE_DIR}/toolchains/${ARMV6})
    file(REMOVE ${CMAKE_BINARY_DIR}/toolchain.tar.gz)
endif()

set(ARMCC_PREFIX ${CMAKE_SOURCE_DIR}/toolchains/${ARMV6}/x64-gcc-6.5.0/arm-rpi-linux-gnueabihf/bin/arm-rpi-linux-gnueabihf-)
set(ARMCC_FLAGS "-march=armv6 -mfpu=vfp -funsafe-math-optimizations")
set(CMAKE_C_COMPILER ${ARMCC_PREFIX}gcc)
set(CMAKE_CXX_COMPILER ${ARMCC_PREFIX}g++)
set(CMAKE_C_FLAGS ${ARMCC_FLAGS})
set(CMAKE_CXX_FLAGS ${ARMCC_FLAGS})
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR armv6)
set(TFLITE_ENABLE_XNNPACK OFF)
#set(CMAKE_VERBOSE_MAKEFILE ON)
