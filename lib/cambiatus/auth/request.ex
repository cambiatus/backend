defmodule Cambiatus.Auth.Request do
  @moduledoc """
  Auth Request Schema, a login attempt
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Cambiatus.Accounts.User

  schema "auth_requests" do
    field(:phrase, :string)
    field(:ip_address, :string)
    belongs_to(:user, User, references: :account, type: :string)

    timestamps()
  end

  @fields ~w(phrase user_id)a

  def changeset(%__MODULE__{} = model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id)
  end
end
