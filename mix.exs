defmodule TflInterp.MixProject do
  use Mix.Project

  def project do
    [
      app: :tfl_interp,
      version: "0.1.2",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "tfl_interp",
      source_url: "https://github.com/shoz-f/tfl_interp.git",

      cmake: cmake()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:poison, "~> 3.1"},
      {:mix_cmake, "~> 0.1.0", only: :dev, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end
  
  # Cmake configuration.
  defp cmake do
    [
      # Specify cmake build directory or pseudo-path {:local, :global}.
      #   :local(default) - "./_build/.cmake_build"
      #   :global - "~/.#{Cmake.app_name()}"
      #
      #build_dir: :local,

      # Specify cmake source directory.(default: File.cwd!)
      #
      #source_dir: File.cwd!,

      # Specify generator name.
      # "cmake --help" shows you build-in generators list.
      #
      #generator: "MSYS Makefiles",

      # Specify jobs parallel level.
      #
      build_parallel_level: 4
    ]
  end

  defp description() do
    "Tensorflow lite intepreter for Elixir."
  end

  defp package() do
    [
       name: "tfl_interp",
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/shoz-f/tfl_interp.git"},
      files: ~w(lib mix.exs README* CHANGELOG* LICENSE* CMakeLists.txt msys2.patch src)
    ]
  end
end
