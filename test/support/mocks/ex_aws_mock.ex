defmodule Cambiatus.ExAwsMock do
  @moduledoc "Mocked implementation of ExAws"

  @spec request(ExAws.Operation.t()) :: {:ok, String.t()} | {:error, String.t()}
  def request(_operation) do
    {:ok, "Success!"}
  end

  defmodule S3 do
    @moduledoc "Mocked implementation of ExAws S3"

    @spec put_object(String.t(), String.t(), String.t()) :: ExAws.Operation.S3.t()
    def put_object(bucket_name, path, content) do
      ExAws.S3.put_object(bucket_name, path, content)
    end
  end
end
