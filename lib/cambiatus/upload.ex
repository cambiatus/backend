defmodule Cambiatus.Upload do
  @moduledoc "Handles file uploading"

  @s3_client Application.get_env(:cambiatus, :s3_client, ExAws)

  @doc """
  Saves a file on the configured Amazon S3 bucket
  """
  @spec upload_file(String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp upload_file(file_contents) do
    bucket_name = System.get_env("BUCKET_NAME")
    file_uuid = UUID.uuid4(:hex)

    operation = @s3_client.S3.put_object(bucket_name, "/#{file_uuid}", file_contents)

    case @s3_client.request(operation) do
      {:ok, _} ->
        {:ok, "https://#{bucket_name}.s3.amazonaws.com/#{bucket_name}/#{file_uuid}"}

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Verifies if the size of the file in the given path is less than 2 megabytes
  """
  @spec is_filesize_valid(File.Stat.t()) :: boolean()
  defp is_filesize_valid(file_info) do
    # 2 megabytes
    if file_info.size > 2_097_152 do
      false
    end

    true
  end

  @doc """
  Verifies if the file in the given path is an image by checking it's magic number
  """
  @spec is_type_valid(String.t()) :: boolean()
  defp is_type_valid(contents) do
    case MagicNumber.detect(contents) do
      {:ok, {:image, _}} ->
        true

      _ ->
        false
    end
  end

  @doc """
  Saves a file
  """
  @spec save(File.Stat.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def save(file_info, file_contents) do
    if not is_filesize_valid(file_info) do
      {:error, "File exceeds 2MB"}
    end

    if not is_type_valid(file_contents) do
      {:error, "File is not an image"}
    end

    upload_file(file_contents)
  end
end
