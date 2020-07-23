defmodule CambiatusWeb.IPFSController do
  use CambiatusWeb, :controller

  def save(conn, params) do
    conn
    |> put_status(:moved_permanently)
    |> redirect(to: CambiatusWeb.UploadController.save(conn, params))
  end
end
