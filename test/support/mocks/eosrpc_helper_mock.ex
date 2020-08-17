defmodule EOSRPC.HelperMock do
  @moduledoc "Mocked implementation of EOSRPC helper"
  @behaviour EOSRPC.Helper

  def new_account(_, _, _, _) do
    {:ok, %{body: %{"transaction_id" => "txidmock"}}}
  end

  def auto_push(_) do
    {:ok, %{body: %{"transaction_id" => "txidmock"}}}
  end

  def get_account(_) do
    {:error, %{body: %{"transaction_id" => "txidmock"}}}
  end
end
