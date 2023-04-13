defmodule TflMnist.MixProject do
  use Mix.Project

  def project do
    [
      app: :tfl_mnist,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {TflMnist.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    System.put_env("SKIP_MAKE_TFLINTERP", "YES")
    [
      {:plug_cowboy, "~> 2.5"},
      {:plug_static_index_html, "~> 1.0"},
      {:jason, "~> 1.2"},
      {:cimg, "~> 0.1.8"},
      {:tfl_interp, path: ".."}
    ]
  end
end
