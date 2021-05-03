defmodule Cambiatus.File.Uploader do
  @moduledoc "Handles file uploading"

  @s3_client Application.compile_env(:cambiatus, :s3_client, ExAws)

  @spec upload_file(String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  defp upload_file(file_contents, content_type) do
    bucket_name = System.get_env("BUCKET_NAME")
    file_uuid = UUID.uuid4(:hex)

    operation =
      @s3_client.S3.put_object(bucket_name, "/#{file_uuid}", file_contents, %{
        content_type: content_type
      })

    case @s3_client.request(operation) do
      {:ok, _} ->
        {:ok, "https://#{bucket_name}.s3.amazonaws.com/#{bucket_name}/#{file_uuid}"}

      {:error, err} ->
        {:error, err}
    end
  end

  @spec validate_filesize(File.Stat.t()) :: :ok | {:error, String.t()}
  defp validate_filesize(file_info) do
    # 2 megabytes
    if file_info.size > 2_097_152 do
      {:error, "File exceeds 2MB"}
    else
      :ok
    end
  end

  @spec validate_filetype(String.t()) :: :ok | {:error, String.t()}
  defp validate_filetype(contents) do
    case MagicNumber.detect(contents) do
      {:ok, {:image, _}} ->
        :ok

      {:ok, {:application, :pdf}} ->
        :ok

      _ ->
        {:error, "File is not an image or PDF"}
    end
  end

  def resize(_, _, _, _, opts \\ [])
  def resize(file_path, "application/pdf", _, _, _), do: %{path: file_path}

  def resize(image_path, _content_type, width, height, opts) do
    image_path
    |> Mogrify.open()
    |> Mogrify.resize_to_limit(~s(#{width}x#{height}))
    |> Mogrify.save(opts)
  end

  # def resize(_, _, _, ) do

  @doc """
  Saves a file
  """
  @spec save(File.Stat.t(), String.t(), String.t()) :: {:ok, String.t()} | {:error, String.t()}
  def save(file_info, content_type, file_contents) do
    with :ok <- validate_filesize(file_info),
         :ok <- validate_filetype(file_contents),
         do: upload_file(file_contents, content_type)
  end
end
