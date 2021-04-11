defmodule Cambiatus.Auth.Ecdsa do
  @moduledoc """
  This module is a wrapper for eosjs-ecc utilizing NIF
  """

  def verify_signature(account, signature, phrase) do
    pub_key =
      account
      |> EosjsAuthWrapper.get_account_info()
      |> get_pub_key()

    EosjsAuthWrapper.verify(signature, phrase, pub_key)
    |> case do
      {:ok, result} -> result
      {:error, _} -> false
    end
  end

  defp get_pub_key(account) do
    account
    |> case do
      {:ok, %{"ok" => account_info}} ->
        account_info
        |> get_in(["permissions", Access.at(0), "required_auth", "keys", Access.at(0), "key"])

      {:error, _} ->
        nil
    end
  end
end
