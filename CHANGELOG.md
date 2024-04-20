# Changelog

## Release 0.1.15(Apl 21 2024)
  * Major Features and Improvements
    * model downloader can handle the zip compressed file - downloading the zip and extract it.
    * tfl_interp GenServer state has the 'memo' slot to keep private data for any purpose. ex. vocablary dict.

## Release 0.1.14(Mar 27 2024)
  * Major Features and Improvements
    * update Tensorflow lite to version 2.16.1.
    * replace Poison with Jason module.

## Release 0.1.13(Jun 4 2023)

  * Major Features and Improvements
    * (experimental) updated backend loader.

## Release 0.1.12(May 31 2023)

  * Major Features and Improvements
    * (experimental) replace environment variable `SKIP_MAKE_TFLINTERP` with "NNCOMPILED" to use the precompiled
      tfl_interp.exe. now, the precompiled tfl_interp.exe is downloaded from GitHub at runtime.

## Release 0.1.11(Apl 29 2023)

  * Major Features and Improvements
    * included custom operations: `ExtractImagePatches`.

  * Bug Fixes and Other Changes
    * add demo applications: Candy, Midas, YoloX and DeepFillV2.
    * revised to shallow clone Tensorflow file set.

## Release 0.1.10(Apl 12 2023)

  * Major Features and Improvements
    * TensorFlow background process has been updated to version 2.12.
    * model downloader now includes a progress bar feature.
    * environment variable `SKIP_MAKE_TFLINTERP` to use the precompiled tfl_interp.exe.
    * included custom operations: `MaxPoolingWithArgmax2D`, `MaxUnpooling2D`, `Convolution2DTransposeBias`.
    * added demo_hairsegmentation.

  * Bug Fixes and Other Changes
    * the build tool chain in Windows has been replaced from MINGW gcc to Visual C++ 2019.

## Release 0.1.9(Dec 18 2022)

  * Major Features and Improvements
    * feed back from AxonInterp project.
    * added demo_yolov4.
    * revised documents.
    * added the ability to download model files from the url.
    * added the ability to give hints about I/O tensor of the model.

## Release 0.1.8(Aug 15 2022)

  * Breaking Changes (from OnnxInterp 0.1.5)
    * the previous download source of nlohmann-json is gone, so changed to another one.

  * Bug Fixes and Other Changes (from OnnxInterp 0.1.4)
    * added two more ways to specify box in NMS.

## Release 0.1.7(Jul 11 2022)

    * fixed non_max_suppression_multi_class/7.

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
