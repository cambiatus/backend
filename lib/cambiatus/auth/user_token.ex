defmodule Cambiatus.Auth.UserToken do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Accounts.User

  schema "user_tokens" do
    field(:phrase, :string)
    field(:token, :binary)
    field(:context, :string)
    field(:user_agent, :string)
    belongs_to(:user, User, references: :account, type: :string)

    timestamps(updated_at: false)
  end

  @required_fields ~w(context user_agent)a

  @optional_fields ~w(phrase token)a

  @doc false
  def changeset(auth_token, attrs, user) do
    auth_token
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:user_id, :context, :user_agent], name: :unique_context)
    |> put_assoc(:user, user)
  end
end
