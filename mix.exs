defmodule TflInterp.MixProject do
  use Mix.Project

  def project do
    [
      app: :tfl_interp,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      #compilers: [:elixir_cmake]++Mix.compilers
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
      #{:elixir_make, "~> 0.6.2", runtime: false},
      #{:elixir_cmake, path: "../elixir-cmake", runtime: false},
      {:poison, "~> 3.1"}
    ]
  end
  
  defp cmake do
    [
      generator: "MSYS Makefiles",
      build_dir: :share
    ]
  end
end
