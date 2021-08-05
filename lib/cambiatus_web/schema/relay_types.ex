defmodule CambiatusWeb.Schema.RelayTypes do
  @moduledoc """
  This module holds Relay specific implementation fields like connection and nodes
  """

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic

  connection node_type: :transfer do
    field(:count, :integer)

    edge do
    end
  end

  connection node_type: :claim do
    field(:count, :integer)

    edge do
    end
  end
end
