defmodule Cambiatus.Commune.NetworkRole do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Cambiatus.Commune.{Network, Role}

  schema "network_roles" do
    belongs_to(:network, Network)
    belongs_to(:role, Role)

    timestamps()
  end

  @required_params ~w(network_id role_id)a
  @optional_params ~w()a

  def changeset(network_roles, params \\ %{}) do
    network_roles
    |> cast(params, @required_params ++ @optional_params)
    |> validate_required(@required_params)
  end
end
