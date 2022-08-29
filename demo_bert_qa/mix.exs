defmodule MBertQA.MixProject do
  use Mix.Project

  def project do
    [
      app: :mbert_qa,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MBertQA.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nx, "~> 0.3.0"},
      {:tfl_interp, path: "..", env: :dev},
    ]
  end
end
