defmodule Cambiatus.Social.NewsReceipt do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

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
    |> unique_constraint([:user_id, :news_id])
    |> validate_required(@required_fields)
  end

  def from_news(query \\ NewsReceipt, news_id) do
    where(query, [r], r.news_id == ^news_id)
  end

  def from_user(query \\ NewsReceipt, user_id) do
    where(query, [r], r.user_id == ^user_id)
  end
end
