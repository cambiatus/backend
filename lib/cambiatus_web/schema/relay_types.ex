defmodule CambiatusWeb.Schema.RelayTypes do
  @moduledoc """
  This module holds Relay specific implementation fields like connection and nodes
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic
  alias CambiatusWeb.Resolvers.Relay

  connection node_type: :transfer do
    field :total_count, :integer do
      resolve(&Relay.get_transfers_total_count/3)
    end

    field :fetched_count, :integer do
      resolve(&Relay.get_transfers_fetched_count/3)
    end

    edge do
    end
  end
end
