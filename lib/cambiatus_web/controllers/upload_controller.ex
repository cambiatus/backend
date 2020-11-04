defmodule CambiatusWeb.UploadController do
  use CambiatusWeb, :controller

  alias Cambiatus.Upload

  def save(conn, params) do
    with %{path: file_path, content_type: content_type} <- Map.get(params, "file"),
         %{path: file_path} <- Upload.resize(file_path, 1200, 1200, in_place: true),
         file_info <- File.lstat!(file_path),
         file_contents <- File.read!(file_path),
         {:ok, url} <- Upload.save(file_info, content_type, file_contents) do
      conn
      |> put_status(200)
      |> json(%{
        data: url
      })
    else
      nil ->
        conn
        |> put_status(422)
        |> json(%{error: "File is required"})

      {:error, err} ->
        conn
        |> put_status(500)
        |> json(%{error: err})
    end
  end
end
