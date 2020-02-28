defmodule CambiatusWeb.InviteView do
  use CambiatusWeb, :view

  alias Cambiatus.Auth.InvitationId

  def render("invite.json", %{result: result}) do
    %{
      data: %{
        id: result.id |> InvitationId.encode(),
        status: "ok",
        message: "Successfully invited"
      }
    }
  end

  def render("error.json", %{error: %Ecto.Changeset{} = _changeset}) do
    %{
      data: %{
        status: "failed",
        message: "Create invitation failed"
      }
    }
  end

  def render("error.json", %{error: value}) when is_binary(value) do
    %{
      data: %{
        status: "failed",
        message: value
      }
    }
  end
end
