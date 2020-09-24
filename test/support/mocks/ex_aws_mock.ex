defmodule Cambiatus.ExAwsMock do
  @moduledoc "Mocked implementation of ExAws"

  @spec request(ExAws.Operation.t()) :: {:ok, String.t()} | {:error, String.t()}
  def request(_operation) do
    {:ok, "Success!"}
  end

  defmodule S3 do
    @moduledoc "Mocked implementation of ExAws S3"

    @spec put_object(binary(), binary(), binary(), ExAws.S3.put_object_opts()) ::
            ExAws.Operation.S3.t()
    def put_object(bucket_name, path, content, opts \\ []) do
      ExAws.S3.put_object(bucket_name, path, content, opts)
    end
  end
end
