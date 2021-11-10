defmodule Cambiatus.Auth.Session do
  @moduledoc """
  Auth Session Schema, a login
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Cambiatus.Accounts.User

  schema "auth_sessions" do
    field(:user_agent, :string)
    field(:ip_address, :string)
    field(:token, :string)
    belongs_to(:user, User, references: :account, type: :string)

    timestamps()
  end

  @fields ~w(user_agent token user_id)a

  def changeset(%__MODULE__{} = model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:user_id)
  end
end
