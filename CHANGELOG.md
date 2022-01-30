# Release 0.1.3(Jan 26 2022)

## Breaking Changes

* change installation methods. see README.md for detail.

## Major Features and Improvements

* move the directory to download Tensorflow to "3rd_party".

* supported Nerves ARMv6, ARMv7NEON and AArch64(not yet tested).

## Bug Fixes and Other Changes

* corrected CMakeLists scripts for MSYS2/MinGW64. 

* revised demo_mnist to fit cimg_ex 0.1.8.

# Release 0.1.2(Jan 17 2022)

## Breaking Changes

## Major Features and Improvements

* remove C++ code that depend on C++20 features: src/tfl_interp.cc.

* limit dependency of mix_cmake to `dev`.

## Bug Fixes and Other Changes
