defmodule ArchethicClient.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    childrens = [
      {Registry, name: ArchethicClient.API.SubscriptionRegistry, keys: :unique},
      {DynamicSupervisor, strategy: :one_for_one, name: ArchethicClient.API.SubscriptionSupervisor}
    ]

    opts = [strategy: :one_for_one, name: ArchethicClient.Supervisor]
    Supervisor.start_link(childrens, opts)
  end
end
