defmodule CambiatusWeb.S3Controller do
  use CambiatusWeb, :controller

  defp save_file(file_path, filename) do
    bucket_name = System.get_env("BUCKET_NAME")
    file_uuid = UUID.uuid4(:hex)
    image_filename = filename
    unique_filename = "#{file_uuid}-#{image_filename}"
    {:ok, image_binary} = File.read(file_path)

    operation = ExAws.S3.put_object(bucket_name, "/#{unique_filename}", image_binary)

    case ExAws.request(operation) do
      {:ok, _} ->
        {:ok, "https://#{bucket_name}.s3.amazonaws.com/#{bucket_name}/#{unique_filename}"}

      _ ->
        {:error}
    end
  end

  def save(conn, params) do
    with %{path: file_path, filename: filename} <- Map.get(params, "file"),
         {:ok, url} <- save_file(file_path, filename) do
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
