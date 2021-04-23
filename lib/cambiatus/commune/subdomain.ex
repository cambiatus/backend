defmodule Cambiatus.Commune.Subdomain do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Commune.Subdomain

  schema "subdomains" do
    field(:name, :string)

    timestamps()
  end

  @required_fields ~w(name)a
  @optional_fields ~w()a

  def changeset(%Subdomain{} = subdomain, attrs) do
    subdomain
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:name)
    |> validate_format(
      :name,
      ~r/^(?!:\/\/)([a-zA-Z0-9-_]+\.)*[a-zA-Z0-9][a-zA-Z0-9-_]+\.[a-zA-Z]{2,11}?$/
    )
  end
end
