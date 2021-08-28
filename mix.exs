defmodule TflInterp.MixProject do
  use Mix.Project

  def project do
    [
      app: :tfl_interp,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

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
      #{:mix_cmake, git: "https://github.com/shoz-f/mix_cmake.git"}
      {:mix_cmake, path: "../../mix_cmake"}
    ]
  end
  
  defp cmake do
    [
      build_dir: :global,
      #source_dir: "."
      #generator: "MSYS Makefiles",
      build_parallel_level: 4
    ]
  end
end
