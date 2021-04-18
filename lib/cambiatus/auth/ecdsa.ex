defmodule Cambiatus.Auth.Ecdsa do
  @moduledoc """
  This module is a wrapper for eosjs-ecc utilizing NIF
  """

  def verify_signature(account, signature, phrase) do
    pub_key =
      account
      |> EosjsAuthWrapper.get_account_info()
      |> get_pub_key()

    signature
    |> EosjsAuthWrapper.verify(phrase, pub_key)
    |> case do
      {:ok, result} -> result
      {:error, _} -> false
    end
  end

  def sign(signature, priv_key) do
    EosjsAuthWrapper.sign(signature, priv_key)
  end

  def sign_with_random(phrase) do
    EosjsAuthWrapper.gen_rand_signature(phrase)
  end

  defp get_pub_key({:ok, %{"error" => err}}), do: {:error, err}
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
