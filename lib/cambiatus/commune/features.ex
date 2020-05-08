defmodule Cambiatus.Commune.Features do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.{
    Commune.Community
  }

  schema "features" do
    field(:actions, :boolean, default: true)
    field(:shop, :boolean, default: true)

    timestamps()

    belongs_to(:community, Community, references: :symbol, type: :string)
  end

  @required_fields ~w(community_id actions shop)a

  @doc false
  def changeset(features, attrs) do
    features
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
