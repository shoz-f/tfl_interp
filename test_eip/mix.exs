defmodule DemoCandy.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_eip,
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
      mod: {TestEip.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    System.put_env("SKIP_MAKE_TFLINTERP", "yes")
    [
      {:tfl_interp, path: ".."},
      {:nx, "~> 0.5.3"}
    ]
  end
end
