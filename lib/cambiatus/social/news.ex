defmodule Cambiatus.Social.News do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Cambiatus.Accounts.User
  alias Cambiatus.Commune
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
    |> validate_admin()
    |> validate_scheduling()
    |> validate_news_enabled()
  end

  def validate_admin(changeset) do
    user = get_field(changeset, :user_id)
    community = get_field(changeset, :community_id)

    if Commune.is_community_admin?(community, user) do
      changeset
    else
      add_error(changeset, :user_id, "is not admin")
    end
  end

  def validate_scheduling(changeset) do
    scheduling = get_field(changeset, :scheduling)

    if is_nil(scheduling) do
      changeset
    else
      if DateTime.compare(scheduling, DateTime.utc_now()) == :gt do
        changeset
      else
        add_error(changeset, :scheduling, "is invalid")
      end
    end
  end

  def validate_news_enabled(changeset) do
    community_id = get_field(changeset, :community_id)

    Commune.get_community(community_id)
    |> case do
      {:ok, community} ->
        if Map.get(community, :has_news),
          do: changeset,
          else: add_error(changeset, :community_id, "news is not enabled")

      {:error, _} ->
        add_error(changeset, :community_id, "does not exist")
    end
  end

  def last_thirty_days(query \\ __MODULE__) do
    where(
      query,
      [n],
      datetime_add(n.updated_at, 60 * 60 * 24 * 30, "second") >= ^NaiveDateTime.utc_now() and
        (is_nil(n.scheduling) or n.scheduling <= ^NaiveDateTime.utc_now())
    )
    |> order_by(asc: :updated_at)
  end
end
