# TflInterp
Tensorflow lite interpreter for Elixir.
Deep Learning inference framework for embedded devices.

## Platform
It has been confirmed to work in the following OS environment.

- Windows MSYS2/MinGW64
- WSL2/Ubuntu 20.04

## Requirements
- cmake 3.18.6 or later
- git

## Installation
This module is designed for Poncho-style. Therefore, it cannot be installed by adding this module to your project's dependency list. Follow the steps below to install.

Download `tfl_interp` to a directory of your choice. I recommend that you put it in the same hierarchy as your Deep Learning project directory.

```shell
$ cd parent-of-your-project
$ git clone https://github.com/shoz-f/tfl_interp.git
```

Then you need to download the file set of Google Tensorflow and build `tfl_intep` executable (Port extended called by Elixir) into ./priv.

Don't worry, `mix_cmake` utility will help you.

```shell
$ cd tfl_interp
$ mix deps.get
$ mix cmake --config

;-) It takes a few minutes to download and build Tensorflow.
```

Now you are ready. The figure below shows the directory structure of tfl_interp.

```
+- your-project
|
+- tfl_interp
     +- _build
     |    +- .cmake_build --- Tensorflow is downloaded here
     +- deps
     +- lib
     +- priv
     |    +- tfl_interp   --- Elixir Port extended
     +- src/
     +- test/
     +- CMakeLists.txt    --- Cmake configuration script
     +- mix.exs           --- includes parameter for mix-cmake task
     +- msys2.patch       --- Patch script for MSYS2/MinGW64
```

## Basic Usage
To use TflInterp in your project, you add the path to `tfl_interp` above to the  `mix.exs`:

```elixir:mix.exs
def deps do
  [
    {:tfl_interp, path: "../tfl_interp"},
  ]
end
```

Then you put the trained model of Tensolflow lite in ./priv.

```shell
$ cp your-trained-model.tflite ./priv
```

The remaining task is to create a module that will interface with your Deep Learning model. The module will probably have pre-processing and post-processing in addition to inference processing, as in the code example below. TflInterp provides only inference processing.

You put `use TflInterp` at the beginning of your module, specify the model path in optional arguments. The inference section involves inputing data to the model - `TflInterp.set_input_tensor/3`, executing it - `TflInterp.invoke/1`, and extracting the results - `TflInterp.get_output_tensor/2`.

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

## License
TflInterp is licensed under the Apache License Version 2.0.
