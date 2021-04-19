defmodule Cambiatus.Auth.Ecdsa do
  @moduledoc """
  This module is a wrapper for eosjs-ecc utilizing NIF
  """
  alias EosjsAuthWrapper, as: EosWrap

  def verify_signature(account, signature, phrase) do
    with account <- EosWrap.get_account_info(account),
         {:ok, pub_key} <- get_pub_key(account),
         {:ok, result} <- EosWrap.verify(signature, phrase, pub_key) do
          result
    else
      {:error, _details} = error -> error
    end
  end

  def sign(signature, priv_key) do
    EosWrap.sign(signature, priv_key)
  end

  def sign_with_random(phrase) do
    EosWrap.gen_rand_signature(phrase)
  end

  def get_pub_key({:ok, %{"error" => err}}), do: {:error, err}
  def get_pub_key(account) do
    account
    |> case do
      {:ok, %{"ok" => account_info}} ->
        pub_key = account_info
        |> get_in(["permissions", Access.at(0), "required_auth", "keys", Access.at(0), "key"])

        {:ok , pub_key}

      {:error, _} -> {:error, "No public key found"}
    end
  end
end
