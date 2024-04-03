defmodule DemoWhisper.MixProject do
  use Mix.Project

  def project do
    [
      app: :demo_whisper,
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
      mod: {DemoWhisper.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    System.put_env("NNCOMPILED", "yes")
    [
      {:tfl_interp, path: ".."},
      {:npy, "~> 0.1.2"},
      {:jason, "~> 1.4"},
    ]
  end
end
