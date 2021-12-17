defmodule Cambiatus.Commune.Role do
  @moduledoc """
  Data structure for roles in Cambiatus, Roles contain permissions and can be used to assign users to a certain group or achievement
  """

  @type t :: %__MODULE__{}

  use Ecto.Schema

  import Ecto.Changeset

  alias Cambiatus.Commune.{Community, Network, Role}

  schema "roles" do
    field(:name, :string)
    field(:color, :string)

    field(:permissions, {:array, Ecto.Enum},
      values: [:invite, :claim, :order, :verify, :sell, :award],
      default: []
    )

    belongs_to(:community, Community, references: :symbol, type: :string)
    many_to_many(:network, Network, join_through: NetworkRoles)

    timestamps()
  end

  @required_fields ~w(name permissions community_id)a
  @optional_fields ~w(color)a

  def changeset(%Role{} = role, attrs) do
    role
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
