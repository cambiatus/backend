defmodule CambiatusWeb.S3Controller do
  use CambiatusWeb, :controller

  def save(conn, params) do
    with %{path: file_path, filename: filename} = Map.get(params, "file") do
      bucket_name = System.get_env("BUCKET_NAME")
      file_uuid = UUID.uuid4(:hex)
      image_filename = filename
      unique_filename = "#{file_uuid}-#{image_filename}"
      {:ok, image_binary} = File.read(file_path)

      ExAws.S3.put_object(bucket_name, unique_filename, image_binary)
      |> ExAws.request!()

      json(conn, %{
        data: "https://#{bucket_name}.s3.amazonaws.com/#{bucket_name}/#{unique_filename}"
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
