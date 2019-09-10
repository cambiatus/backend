defmodule BeSpiral.Auth.Invitation do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  schema "invitations" do
    field(:accepted, :boolean, default: false)
    field(:community, :string)
    field(:invitee_email, :string)
    field(:inviter, :string)

    timestamps()
  end

  @doc false
  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:community, :inviter, :invitee_email, :accepted])
    |> validate_required([:invitee_email, :inviter, :community])
    |> validate_format(:invitee_email, ~r/@/)
    |> unique_constraint(:invitee_email, name: :invitations_community_invitee_index)
  end
end
