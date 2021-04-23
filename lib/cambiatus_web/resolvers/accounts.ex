defmodule CambiatusWeb.Resolvers.Accounts do
  @moduledoc """
  This module holds the implementation of the resolver for the accounts context
  use this to resolve any queries and mutations for Accounts
  """

  alias Cambiatus.{
    Accounts,
    Auth,
    Auth.SignUp
  }

  alias Cambiatus.Accounts.{User, Transfers}

  @doc """
  Collects profile info
  """
  def get_user(_, %{account: account}, _) do
    Accounts.get_account_profile(account)
  end

  def get_payers_by_account(%User{} = user, %{account: _} = payer, _) do
    Accounts.get_payers_by_account(user, payer)
  end

  @doc """
  Updates a user
  """
  def update_user(_, %{input: params}, %{context: %{current_user: current_user}}) do
    current_user
    |> Accounts.update_user(params)
    |> case do
      {:ok, updated_user} ->
        {:ok, updated_user}

      {:error, changeset} ->
        {:error, message: "Could not update user", details: Cambiatus.Error.from(changeset)}
    end
  end

  def get_auth_session(_, %{account: account}, %{context: %{user_agent: user_agent}}) do

    with %User{} = user <- Accounts.get_user(account),
         {:ok, phrase} <- Auth.gen_auth_phrase(user, user_agent) do
      {:ok, phrase}
    else
      nil -> {:error, "Account not found"}
      err -> err
    end
  end

  def sign_in(_, %{account: account, password: password}, _) do
    case Auth.sign_in(account, password) do
      {:error, reason} ->
        {:error, message: "Sign In failed", details: Cambiatus.Error.from(reason)}

      {:ok, user} ->
        {:ok, %{user: user, token: CambiatusWeb.AuthToken.sign(user)}}
    end
  end

  def sign_in(_, %{signature: signature}, %{context: %{phrase: phrase, user_agent: user_agent}}) do
    with {:ok, {user, token}} <- Auth.verify_signature(phrase, signature, user_agent) do
      {:ok, %{user: user, token: token}}
    else
      {:error, _details} = error -> error
    end
  end

  def sign_in(_, %{account: account, password: password, invitation_id: invitation_id}, _) do
    case Auth.sign_in(account, password, invitation_id) do
      {:error, reason} ->
        {:error, message: "Sign In failed", details: Cambiatus.Error.from(reason)}

      {:ok, user} ->
        {:ok, %{user: user, token: CambiatusWeb.AuthToken.sign(user)}}
    end
  end

  def sign_up(_, args, %{context: %{user_agent: user_agent}}) do
    case SignUp.sign_up(args) do
      {:error, reason, details} ->
        Sentry.capture_message("Sign up failed", extra: %{error: reason, details: details})
        {:error, message: reason, details: details}

      {:error, reason} ->
        Sentry.capture_message("Sign up failed", extra: %{error: reason})
        {:error, message: "Couldn't create user", details: Cambiatus.Error.from(reason)}

      {:ok, user} ->
        session_token = Auth.create_session(user, user_agent)
        {:ok, %{user: user, token: session_token}}
    end
  end

  def sign_out(_, _, %{context: %{current_user: user}}) do
    with {1, nil} <- Auth.delete_user_token(%{account: user.account, filter: :session}) do
      {:ok, "Logged out"}
    else
      _error -> {:error, "Unable to sign out"}
    end
  end

  @doc """
  Collects transfers belonging to the given user according various criteria, provided in `args`.
  """
  @spec get_transfers(map(), map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%User{} = user, args, _) do
    case Transfers.get_transfers(user, args) do
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
