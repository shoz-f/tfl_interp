defmodule DemoMovenet.MixProject do
  use Mix.Project

  def project do
    [
      app: :demo_movenet,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {DemoMovenet.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tfl_interp, path: ".."},
      {:nx, "~> 0.4.0"},
      {:cimg, path: "../../cimg_ex"},
      {:postdnn, "~> 0.1.4"}
    ]
  end
end
