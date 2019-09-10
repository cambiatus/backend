defmodule EOSRPC.WalletMock do
  @moduledoc "Mocked implementation of EOSRPC wallet"
  @behaviour EOSRPC.Wallet

  def unlock(_, _), do: {:ok, %{}}

  def sign_transaction(_, _) do
    {:ok, %{}}
  end

  def url(_), do: ""
end
