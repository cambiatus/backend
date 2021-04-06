defmodule Cambiatus.Auth.UserToken do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Accounts.User

  schema "user_tokens" do
    field(:phrase, :string)
    field(:token, :binary)
    field(:context, :string)
    belongs_to(:user, User, references: :account, type: :string)

    timestamps(updated_at: false)
  end

  @required_fields ~w(token context)a
  @optional_fields ~w(phrase)a
  @doc false
  def changeset(auth_token, attrs, user) do
    auth_token
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:user_id, :context], name: :unique_context)
    |> put_assoc(:user, user)
  end
end
