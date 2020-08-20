defmodule EOSRPC.ChainMock do
  @moduledoc "Mocked implementation of EOSRPC Chain"
  @behaviour EOSRPC.Chain

  def get_account(_) do
    {:error, %{body: %{"transaction_id" => "txidmock"}}}
  end
end
