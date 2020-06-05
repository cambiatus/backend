defmodule CambiatusWeb.Resolvers.Accounts do
  @moduledoc """
  This module holds the implementation of the resolver for the accounts context
  use this to resolve any queries and mutations for Accounts
  """
  alias Cambiatus.{
    Accounts,
    Accounts.User,
    Commune
  }

  @doc """
  Collects profile info
  """
  @spec get_profile(map(), map(), map()) :: {:ok, User.t()} | {:error, term()}
  def get_profile(_, %{input: params}, _) do
    Accounts.get_account_profile(params.account)
  end

  @spec get_payers_by_account(map(), map(), map()) :: {:ok, list()}
  def get_payers_by_account(%User{} = recipient, %{account: account} = payer, _) do
    Accounts.get_payers_by_account(recipient.account, payer.account)
  end

  @doc "Resolve fetched transfers to the given user"
  @spec get_payment_history(map(), map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_payment_history(_, args, _) do
    {:ok, transfers} = Accounts.get_payment_history(args)
    {:ok, transfers}
  end

  @doc """
  Updates an a user account profile info
  """
  @spec update_profile(map(), map(), map()) :: {:ok, User.t()} | {:error, term()}
  def update_profile(_, %{input: params}, _) do
    with {:ok, acc} <- Accounts.get_account_profile(params.account),
         {:ok, prof} <- Accounts.update_user(acc, params) do
      {:ok, prof}
    end
  end

  @doc """
  Collects all transfers from a given user
  """
  @spec get_transfers(map(), map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%User{} = user, args, _) do
    {:ok, transfers} = Commune.get_transfers(user, args)

    result =
      transfers
      |> Map.put(:parent, user)

    {:ok, result}
  end

  def get_analysis_count(%User{} = user, _, _) do
    Accounts.get_analysis_count(user)
  end
end
