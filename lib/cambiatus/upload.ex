defmodule Cambiatus.Upload do
  @moduledoc "Handles file uploading"

  @doc """
  Saves a file on the configured Amazon S3 bucket
  """
  @spec upload_file(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp upload_file(file_path) do
    bucket_name = System.get_env("BUCKET_NAME")
    file_uuid = UUID.uuid4(:hex)
    image_binary = File.read!(file_path)

    operation = ExAws.S3.put_object(bucket_name, "/#{file_uuid}", image_binary)

    case ExAws.request(operation) do
      {:ok, _} ->
        {:ok, "https://#{bucket_name}.s3.amazonaws.com/#{bucket_name}/#{file_uuid}"}

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Verifies if the size of the file in the given path is less than 2 megabytes
  """
  @spec is_filesize_valid(String.t()) :: boolean()
  defp is_filesize_valid(file_path) do
    info = File.lstat!(file_path)

    # 2 megabytes
    if info.size > 2_097_152 do
      false
    end

    true
  end

  @doc """
  Verifies if the file in the given path is an image by checking it's magic number
  """
  @spec is_type_valid(String.t()) :: boolean()
  defp is_type_valid(file_path) do
    contents = File.read!(file_path)

    case MagicNumber.detect(contents) do
      {:ok, {:image, _}} ->
        true

      :error ->
        false
    end
  end

  @doc """
  Saves a file
  """
  @spec save(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def save(file_path) do
    if not is_filesize_valid(file_path) do
      {:error, "File exceeds 2MB"}
    end

    if not is_type_valid(file_path) do
      {:error, "File is not an image"}
    end

    upload_file(file_path)
  end
end
