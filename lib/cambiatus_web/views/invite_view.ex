defmodule CambiatusWeb.InviteView do
  use CambiatusWeb, :view

  def render("invite.json", %{result: result}) do
    %{
      invites: Enum.map(result, &invite/1)
    }
  end

  def invite({:error, changeset}) do
    %{
      invitee: changeset.changes.invitee_email,
      status: "failed",
      message: "Invitation failed"
    }
  end

  def invite({:ok, invitation}) do
    %{
      invitee: invitation.invitee_email,
      status: "ok",
      message: "Successfully invited"
    }
  end
end
