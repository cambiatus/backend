defmodule CambiatusWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use CambiatusWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(CambiatusWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(CambiatusWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, {:error, :user_already_registered}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(CambiatusWeb.AuthView)
    |> render("unauthorized.json")
  end

  def call(conn, generic_error) do
    conn
    |> put_status(:internal_server_error)
    |> put_view(CambiatusWeb.ErrorView)
    |> render("500.json", generic_error)
  end

  defp call_chat_render(conn, status, error) do
    conn
    |> put_status(status)
    |> put_view(CambiatusWeb.AuthView)
    |> render("chat_error.json", %{error: error})
  end
end
