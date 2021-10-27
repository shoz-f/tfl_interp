# TflInterp
Tensorflow lite interpreter for Elixir.

## Platform
- Windows MSYS2/MinGW64
- WSL2/Ubuntu 20.04

## Requirements
- cmake 3.18.6 or later

## Installation
This module is designed for Poncho-style projects. So we recommended you create a parent directory and put both your application
and this module under it.

```bash
mkdir a_project
cd a_project
git clone https://github.com/shoz-f/tfl_interp.git
mix new your_app
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
