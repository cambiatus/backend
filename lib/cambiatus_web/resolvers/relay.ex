defmodule CambiatusWeb.Resolvers.Relay do
  @moduledoc """
  This module holds the implementation of the resolver related to Relay
  """

  alias Cambiatus.Commune

  def get_transfers_total_count(%{parent: parent}, _args, _info) do
    Commune.get_transfers_count(parent)
  end

  def get_transfers_fetched_count(%{edges: edges}, _args, _info) do
    count = Enum.count(edges)
    {:ok, count}
  end
end
