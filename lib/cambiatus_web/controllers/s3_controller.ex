defmodule CambiatusWeb.S3Controller do
  use CambiatusWeb, :controller

  alias Cambiatus.Upload

  def save(conn, params) do
    with %{path: file_path} <- Map.get(params, "file"),
         file_info <- File.lstat!(file_path),
         file_contents <- File.read!(file_path),
         {:ok, url} <- Upload.save(file_info, file_contents) do
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
