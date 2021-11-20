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

Download `TflInterp` to a directory of your choice. I recommend that you put it in the same hierarchy as your Deep Learning project directory.

```shell
$ cd parent-of-your-project
$ git clone https://github.com/shoz-f/tfl_interp.git
```

Then you need to download the file set of Google Tensorflow and build `tfl_intep` executable (extended command called by Elixir) into ./priv.
Don't worry. The mix_cmake utility will help you.

```shell
$ cd tfl_interp
$ mix deps.get
$ mix cmake --config

;-) It takes a few minutes to download and build Tensorflow.
```

Now you are ready. The figure below shows the directory structure of tfl_interp.

```
- tfl_interp
    +- _build
    |    +- .cmake_build --- Tensorflow is downloaded here
    +- deps
    +- lib
    +- priv
    |    +- tfl_interp   --- Elixir Port extended command
    +- src/
    +- test/
    +- CMakeLists.txt    --- Cmake configuration script
    +- mix.exs           --- includes parameter for mix-cmake task
    +- msys2.patch       --- Patch script for MSYS2/MinGW64
```

## Usage

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `tfl_interp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tfl_interp, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/tfl_interp](https://hexdocs.pm/tfl_interp).

## License
TflInterp is licensed under the Apache License Version 2.0.
