defmodule Cambiatus.Social.News do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Accounts.User
  alias Cambiatus.Commune.Community

  schema "news" do
    field(:title, :string)
    field(:description, :string)
    field(:scheduling, :utc_datetime)

    belongs_to(:community, Community, references: :symbol, type: :string)
    belongs_to(:user, User, references: :account, type: :string)

    timestamps()
  end

  @required_fields ~w(title description community_id user_id)a
  @optional_fields ~w(scheduling)a

  def changeset(model, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> foreign_key_constraint(:community_id)
    |> foreign_key_constraint(:user_id)
    |> validate_required(@required_fields)
  end
end
