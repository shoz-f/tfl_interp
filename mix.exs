defmodule TflInterp.MixProject do
  use Mix.Project

  def project do
    [
      app: :tfl_interp,
      version: "0.1.0",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      compilers: [:cmake]++Mix.compilers(),
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
      {:mix_cmake, git: "https://github.com/shoz-f/mix_cmake.git"}
    ]
  end
  
  defp cmake do
    [
      #generator: "MSYS Makefiles",
      build_dir: :global,
      #source_dir: "."
      #install_prefix: "."

      #config_opts:  [],
      build_opts:   ["-j4", "--target", "tfl_interp/fast"],
      #install_opts: []
    ]
  end
end
