# TflInterp
Tensorflow lite interpreter for Elixir.
Deep Learning inference framework for embedded devices.

## Design policy (Features)
TflInterp is designed based on the following policy.

1. Provide only the Deep Learning inference. It aims to the poor-resource devices such as IOT and mobile.
2. Easy to understand. The inference part, excluding pre/post-processing, can be written in a few lines.
3. Use trained models from major Deep Learning frameworks that are easy to obtain.
4. Multiple inference models can be used from a single application.
5. There are few dependent modules. It does not have image processing or matrix calculation functions.
6. TflInterp does not block the erlang/elixir process scheduler. It runs as an OS process outside of elixir.
7. The back-end inference engine can be easily replaced. It's easy to keep up with the latest Deep Learninig technology.

And I'm trying to make TflInterp easy to install. 

### short or concise history
The development of Tflinterp started in 2020 Nov. The original idea was to use Nerves to create an AI remote controlled car.
In the first version, I implemented Yolo3, but the design strongly depended on that model, which made it difficult to use in other applications.
Reflecting on that mistake, I redesigned Tflinterp according to the above design guidelines.

## Platform
It has been confirmed to work in the following OS environment.

- Windows Visual C++ 2019
- WSL2/Ubuntu 20.04
- Nerves ARMv6, ARMv7NEON and AArch64

## Requirements
- cmake 3.18.6 or later
- git
- Visual C++ 2019 for Windows

## Installation
Since 0.1.3, the installation method of this module has changed.
You may need to remove previously installed TflInterp before installing new version.

There are two installation methods. You can choose either one according to your purpose.

Method-1. Like any other elixir module, add TflInterp to the dependency list in the mix.exs.

```
def deps do
  [
    ...
    {:tfl_interp, "~> 0.1.10"},
  ]
end
```

Method-2. Download TflInterp to a directory and build it ahead of time.

```
# download TflInterp in advance.
$ cd /home/{your home}/workdir
$ git clone -b nerves https://github.com/shoz-f/tfl_interp.git
$ cd tfl_interp
$ mix deps.get
$ mix compile
```

After adding the directory path to the dependency list in your mix.exs file, add the following line to the deps() function: `System.put_env("SKIP_MAKE_TFLINTERP", "YES")`

This line sets an environment variable that instructs your TflInterp application to use the precompiled tfl_interp.exe file, eliminating the need to build it again.

```
def deps do
  System.put_env("SKIP_MAKE_TFLINTERP", "YES)
  [
    ...
    {:tfl_interp, path: "/home/{your home}/workdir/tfl_interp"}
  ]
end
```

Then you run the following commands in your application project.

For Desktop application:

```
$ mix deps.get
$ mix compile
```

For Nerves application:

```
$ export MIX_TARGET=rpi3  # <- specify target device tag
$ mix deps.get
$ mix firmware
```

It takes a long time to finish the build. Because it will download the required files - Tensorflow sources,
ARM toolchain [^1], etc - at the first build time.
Method 1 saves the downloaded files under "{your app}/deps/tfl_interp". On the other hand,
method 2 saves them under "/home/{your home}/workdir/tfl_interp".
If you want to reuse the downloaded files in other applications, I recommend Method 2.

In either method 1 or 2, the external modules required for Tensorflow lite are stored under
their "_build/{target}/.cmake_build" according to the cmakelists.txt that comes with Tensorflow.

 [^1] Unfortunately, the ARM toolchain that comes with Nerves can not build Tensorflow lite. We need to get the toolchain recommended by the Tensorflow project.

After installation, you will have the directory tree like these:

Method 1

```
work_dir
  +- your-app
       +- _build/
       |    +- dev/
       |         +- .cmake_build/ --- CMakeCash.txt and external modules that Tensorflowlite depends on.
       |         |                    The cmake build outputs are stored here also.
       |         +- lib/
       |         |    +- tfl_interp
       |         |         +- ebin/
       |         |         +- priv
       |         |              +- tfl_interp --- executable: tensorflow interpreter.
       |         :
       |
       +- deps/
       |    + tfl_interp
       |    |   +- 3rd_party/ --- Tensorflow sources, etc.
       |    |   +- lib/ --- TflInterp module.
       |    |   +- src/ --- tfl_interp C++ sources.
       |    |   +- test/
       |    |   +- toolchain/ --- ARM toolchains for Nerves.
       |    |   +- CMakeLists.txt --- CMake configuration for for building tfl_interp.
       |    |   +- mix.exs
       |    :
       |
       +- lib/
       +- test/
       +- mix.exs
```

Method 2

```
work_dir
  +- your-app
  |    +- _build/
  |    |    +- dev/
  |    |         +- lib/
  |    |         |    +- tfl_interp
  |    |         |         +- ebin/
  |    |         |         +- priv
  |    |         |              +- tfl_interp --- executable: tensorflow interpreter.
  |    |         |                                copy it from the tfl_interp project.
  |    |         :
  |    |
  |    +- deps/
  |    +- lib/
  |    +- test/
  |    +- mix.exs
  |
  +- tfl_interp
       +- 3rd_party/ --- Tensorflow sources, etc.
       +- _build/
       |    +- dev/
       |         +- .cmake_build/ --- CMakeCash.txt and external modules that Tensorflowlite depends on.
       |         |                    The cmake build outputs are stored here also.
       |         +- lib/
       |         |    +- tfl_interp
       |         |         +- ebin/
       |         |         +- priv
       |         |              +- tfl_interp --- executable: tensorflow interpreter.
       |         :
       |
       +- deps/
       +- lib/ --- TflInterp module.
       +- src/ --- tfl_interp C++ sources.
       +- test/
       +- toolchain/ --- ARM toolchains for Nerves.
       +- CMakeLists.txt --- CMake configuration for for building tfl_interp.
       +- mix.exs
```

## Basic Usage
You get the trained tflite model and save it in a directory that your application can read.
"your-app/priv" may be good choice.

```
$ cp your-trained-model.tflite ./priv
```

Next, you will create a module that interfaces with the deep learning model. The module will need pre-processing and
post-processing in addition to inference processing, as in the example following. TflInterp provides inference processing only.

You put `use TflInterp` at the beginning of your module, specify the model path as an optional argument. In the inference
section, you will put data input to the model (`TflInterp.set_input_tensor/3`), inference execution (`TflInterp.invoke/1`),
and inference result retrieval (`TflInterp.get_output_tensor/2`).

```elixr:your_model.ex
defmodule YourApp.YourModel do
  use TflInterp, model: "priv/your-trained-model.tflite"

  def predict(data) do
    # preprocess
    #  to convert the data to be inferred to the input format of the model.
    input_bin = convert-float32-binaries(data)

    # inference
    #  typical I/O data for Tensorflow lite models is a serialized 32-bit float tensor.
    output_bin =
      __MODULE__
      |> TflInterp.set_input_tensor(0, input_bin)
      |> TflInterp.invoke()
      |> TflInterp.get_output_tensor(0)

    # postprocess
    #  add your post-processing here.
    #  you may need to reshape output_bin to tensor at first.
    tensor = output_bin
      |> Nx.from_binary({:f, 32})
      |> Nx.reshape({size-x, size-y, :auto})

    * your-postprocessing *
    ...
  end
end
```

Let's enjoy ;-)

## Demo
There is MNIST web application in demo_mnist directory. You can do it by following the steps below.

```shell
$ cd demo_mnist
$ mix deps.get
$ mix run --no-halt
```

And then, please open your browser with "http://localhost:5000".

## License
TflInterp is licensed under the Apache License Version 2.0.
