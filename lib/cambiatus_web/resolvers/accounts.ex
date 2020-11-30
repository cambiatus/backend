defmodule CambiatusWeb.Resolvers.Accounts do
  @moduledoc """
  This module holds the implementation of the resolver for the accounts context
  use this to resolve any queries and mutations for Accounts
  """
  alias Cambiatus.{
    Accounts,
    Accounts.User,
    Kyc.KycData
  }

  @doc """
  Collects profile info
  """
  @spec get_profile(map(), map(), map()) :: {:ok, User.t()} | {:error, term()}
  def get_profile(_, %{input: params}, _) do
    Accounts.get_account_profile(params.account)
  end

  @spec get_payers_by_account(map(), map(), map()) :: {:ok, list()}
  def get_payers_by_account(%User{} = user, %{account: _} = payer, _) do
    Accounts.get_payers_by_account(user, payer)
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
  Creates Natural user with the given account and KYC.
  """
  def create_user(_, %{input: params, kyc: kyc}, _) do
    # TODO:
    # 1. Validate sign_up params
    # 2. Validate KYC params
    # 3. If both are valid, then run sign_up and upsert_kyc

    sign_up_fields = %{name: params.name, account: params.account, email: params.email}
    account_changeset = Accounts.change_user(sign_up_fields)

    if account_changeset.valid? do
      kyc_changeset = KycData.changeset(%KycData{}, kyc)

      if kyc_changeset.valid? do
        IO.inspect("kyc data is valid")

        params
        |> Cambiatus.Auth.sign_up()
        |> case do
          {:error, reason} ->
            Sentry.capture_message("Sign up failed", extra: %{error: reason})
            {:ok, %{status: :error, reason: reason}}

          _ ->
            # TODO: run upsert_kyc here
            {:ok, %{status: :success, reason: ""}}
        end
      else
        IO.inspect(KycData.changeset(%KycData{}, kyc),
          label: "kyc fields are INvalid"
        )

        # TODO: return reasonable error message
        {:ok, %{status: :error, reason: "#{inspect(kyc_changeset.errors)}"}}
      end
    else
      # TODO: return reasonable error message
      {:ok, %{status: :error, reason: "#{inspect(account_changeset.errors)}"}}
    end
  end

  @doc """
  Updates an a user account profile info
  """
  @spec create_user(map(), map(), map()) :: {:ok, User.t()} | {:error, term()}
  def create_user(_, %{input: params}, _) do
    params
    |> Cambiatus.Auth.sign_up()
    |> case do
      {:error, reason} ->
        Sentry.capture_message("Sign up failed", extra: %{error: reason})
        {:ok, %{status: :error, reason: reason}}

      _ ->
        {:ok, %{status: :success, reason: ""}}
    end
  end

  @doc """
  Collects transfers belonging to the given user according various criteria, provided in `args`.
  """
  @spec get_transfers(map(), map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%User{} = user, args, _) do
    case Accounts.Transfers.get_transfers(user, args) do
      {:ok, transfers} ->
        result =
          transfers
          |> Map.put(:parent, user)

        {:ok, result}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def get_analysis_count(%User{} = user, _, _) do
    Accounts.get_analysis_count(user)
  end
end
