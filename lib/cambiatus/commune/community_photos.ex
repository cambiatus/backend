defmodule Cambiatus.Commune.CommunityPhotos do
  @moduledoc """
  Upload model for the uploads table
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cambiatus.Commune.{Community, CommunityPhotos}

  @url_regex ~r/ https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/

  schema "communities_photos" do
    field(:url, :string)
    belongs_to(:community, Community, references: :symbol, type: :string)

    timestamps()
  end

  @required_fields ~w(url community_id)a
  @optional_fields ~w()a

  def changeset(%CommunityPhotos{} = upload, attrs) do
    upload
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:url, @url_regex)
  end
end
