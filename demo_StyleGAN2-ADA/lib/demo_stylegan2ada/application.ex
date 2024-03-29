defmodule DemoStyleGAN2ADA.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      StyleGAN2ADA.Mapping,
      StyleGAN2ADA.Synthesis
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DemoStyleGAN2ADA.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
