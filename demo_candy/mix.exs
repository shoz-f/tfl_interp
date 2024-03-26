defmodule DemoCandy.MixProject do
  use Mix.Project

  def project do
    [
      app: :demo_candy,
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
      mod: {DemoCandy.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    System.put_env("NNCOMPILED", "yes")
    [
      {:tfl_interp, path: ".."},
      {:cimg, "~> 0.1.20"}
    ]
  end
end
