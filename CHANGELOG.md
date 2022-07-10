# Changelog

## Release 0.1.7(2022)

    * fixed command message of non_max_suppression_multi_class/7.

## Release 0.1.6(Jun 29 2022)

  * Major Features and Improvements
    * Feedback based on OnnxInterp design.
    * update Tensorflow to 2.9.1.

## Release 0.1.5(Apl 4 2022)

  * Major Features and Improvements
    * add session mode.
    * add processing time measurement function.
    * update Tensorflow to 2.8.0.

## Release 0.1.4(Feb 6 2022)

  * Bug Fixes and Other Changes
    * adjust word alignment of NMS parameter to ARMs.

## Release 0.1.3(Jan 30 2022)

  * Breaking Changes
    * change installation methods. see README.md for detail.

  * Major Features and Improvements
    * move the directory to download Tensorflow to "3rd_party".
    * supported Nerves ARMv6, ARMv7NEON and AArch64(not yet tested).

  * Bug Fixes and Other Changes
    * corrected CMakeLists scripts for MSYS2/MinGW64. 
    * revised demo_mnist to fit cimg_ex 0.1.8.

## Release 0.1.2(Jan 17 2022)

  * Breaking Changes

  * Major Features and Improvements
    * remove C++ code that depend on C++20 features: src/tfl_interp.cc.
    * limit dependency of mix_cmake to `dev`.

  * Bug Fixes and Other Changes
