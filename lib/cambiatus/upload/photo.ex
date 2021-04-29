defmodule Cambiatus.Upload.Photo do
  @moduledoc """
  Photo model for the photos table
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Accounts.User
  alias Cambiatus.Upload.Photo

  @url_regex ~r/ https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/

  schema "photos" do
    field(:url, :string)

    belongs_to(:user, User, references: :account, type: :string)
    timestamps()
  end

  @required_fields ~w(url user_id)a
  @optional_fields ~w()a

  def changeset(%Photo{} = photo, attrs) do
    photo
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:url, @url_regex)
  end
end
