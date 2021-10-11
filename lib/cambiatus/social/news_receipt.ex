defmodule Cambiatus.Social.NewsReceipt do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Accounts.User
  alias Cambiatus.Social.News

  schema "news_receipts" do
    field(:reactions, {:array, :string})

    belongs_to(:news, News)
    belongs_to(:user, User, references: :account, type: :string)

    timestamps()
  end

  @required_fields ~w(reactions news_id user_id)a

  def changeset(model, params) do
    model
    |> cast(params, @required_fields)
    |> foreign_key_constraint(:news_id)
    |> foreign_key_constraint(:user_id)
    |> validate_required(@required_fields)
  end
end
