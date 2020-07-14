defmodule CambiatusWeb.S3Controller do
  use CambiatusWeb, :controller

  defp validate_file_size(file_path) do
    info = File.lstat!(file_path)

    # 2 megabytes
    if info.size > 2_097_152 do
      {:error, "File exceeds 2 megabytes"}
    end

    {:ok}
  end

  defp validate_file_type(file_path) do
    contents = File.read!(file_path)

    case MagicNumber.detect(contents) do
      {:ok, {:image, _}} ->
        {:ok}

      _ ->
        {:error, "Mime type not detected"}
    end
  end

  defp save_file(file_path, filename) do
    bucket_name = System.get_env("BUCKET_NAME")
    file_uuid = UUID.uuid4(:hex)
    image_filename = filename
    unique_filename = "#{file_uuid}-#{image_filename}"
    image_binary = File.read!(file_path)

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
         {:ok} <- validate_file_size(file_path),
         {:ok} <- validate_file_type(file_path),
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
