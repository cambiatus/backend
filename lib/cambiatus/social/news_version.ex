defmodule Cambiatus.Social.NewsVersion do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Cambiatus.Accounts.User
  alias Cambiatus.Social.News

  schema "news_versions" do
    field(:title, :string)
    field(:description, :string)
    field(:scheduling, :utc_datetime)

    belongs_to(:news, News)
    belongs_to(:user, User, references: :account, type: :string)

    timestamps()
  end

  @required_fields ~w(title description news_id user_id)a
  @optional_fields ~w(scheduling)a

  def changeset(model, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> foreign_key_constraint(:news_id)
    |> foreign_key_constraint(:user_id)
    |> validate_required(@required_fields)
  end

  def from_news(query \\ NewsVersion, news_id) do
    where(query, [v], v.news_id == ^news_id)
  end
end
