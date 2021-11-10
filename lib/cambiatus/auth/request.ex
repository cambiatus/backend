defmodule Cambiatus.Auth.Request do
  @moduledoc """
  Auth Request Schema, a login attempt
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Cambiatus.Accounts.User

  schema "auth_requests" do
    field(:phrase, :string)
    field(:ip_address, :string)
    belongs_to(:user, User, references: :account, type: :string)

    timestamps()
  end

  @fields ~w(phrase ip_address user_id)a

  def changeset(%__MODULE__{} = model, params \\ %{}) do
    model
    |> cast(params, @fields)
    |> validate_required(@fields)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint(:user_id)
  end

  def not_expired(query \\ Request) do
    where(query, [r], datetime_add(r.updated_at, 30, "second") >= ^NaiveDateTime.utc_now())
  end

  def from_user(query \\ Request, account) do
    where(query, [r], r.user_id == ^account)
  end

  def expired(query \\ Request) do
    where(query, [r], datetime_add(r.updated_at, 30, "second") <= ^NaiveDateTime.utc_now())
  end
end
