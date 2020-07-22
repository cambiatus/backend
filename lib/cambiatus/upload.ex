defmodule Cambiatus.Upload do
  @moduledoc "Handles file uploading"

  @doc """
  Saves a file on the configured Amazon S3 bucket
  """
  @spec save_file(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def save_file(file_path, filename) do
    bucket_name = System.get_env("BUCKET_NAME")
    file_uuid = UUID.uuid4(:hex)
    image_filename = filename
    unique_filename = "#{file_uuid}-#{image_filename}"
    image_binary = File.read!(file_path)

    operation = ExAws.S3.put_object(bucket_name, "/#{unique_filename}", image_binary)

    case ExAws.request(operation) do
      {:ok, _} ->
        {:ok, "https://#{bucket_name}.s3.amazonaws.com/#{bucket_name}/#{unique_filename}"}

      {:error, err} ->
        {:error, err}
    end
  end

  @doc """
  Verifies if the size of the file in the given path is less than 2 megabytes
  """
  @spec validate_file_size(String.t()) :: :ok | {:error, String.t()}
  def validate_file_size(file_path) do
    info = File.lstat!(file_path)

    # 2 megabytes
    if info.size > 2_097_152 do
      {:error, "File exceeds 2 megabytes"}
    end

    :ok
  end

  @doc """
  Verifies if the file in the given path is an image by checking it's magic number
  """
  @spec validate_file_type(String.t()) :: :ok | {:error, String.t()}
  def validate_file_type(file_path) do
    contents = File.read!(file_path)

    case MagicNumber.detect(contents) do
      {:ok, {:image, _}} ->
        :ok

      :error ->
        {:error, "Mime type not detected"}
    end
  end
end
