defmodule CambiatusWeb.S3Controller do
  use CambiatusWeb, :controller

  alias Cambiatus.Upload

  def save(conn, params) do
    with %{path: file_path, filename: filename} <- Map.get(params, "file"),
         true <- Upload.is_filesize_valid(file_path),
         true <- Upload.is_type_valid(file_path),
         {:ok, url} <- Upload.save_file(file_path, filename) do
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

      _ ->
        conn
        |> put_status(500)
        |> json(%{error: "Something went wrong while uploading your image"})
    end
  end
end
