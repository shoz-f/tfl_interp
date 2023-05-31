defmodule DemoDeepFillV2.MixProject do
  use Mix.Project

  def project do
    [
      app: :demo_deepfillv2,
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
      mod: {DemoDeepFillV2.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    System.put_env("CMAKE_SKIP", "yes")
    [
      {:tfl_interp, path: "..", system_env: [{"CMAKE_ENV", "HELLOW"}]},
      {:nx, "~> 0.4.0"},
      {:cimg, "~> 0.1.19"}
    ]
  end
end
