defmodule CambiatusWeb.Resolvers.Accounts do
  @moduledoc """
  This module holds the implementation of the resolver for the accounts context
  use this to resolve any queries and mutations for Accounts
  """

  alias Absinthe.Relay.Connection
  alias Cambiatus.{Accounts, Auth.SignUp, Auth.SignIn}
  alias Cambiatus.Accounts.User
  alias Cambiatus.Commune.Transfer

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

  def sign_in(_, %{account: account, password: password, invitation_id: invitation_id}, _) do
    case SignIn.sign_in(account, password, invitation_id: invitation_id) do
      {:error, reason} ->
        {:error, message: "Sign In failed", details: Cambiatus.Error.from(reason)}

      {:ok, user} ->
        {:ok, %{user: user, token: CambiatusWeb.AuthToken.sign(user)}}
    end
  end

  def sign_in(_, %{account: account, password: password}, %{context: %{domain: domain}}) do
    case SignIn.sign_in(account, password, domain: domain) do
      {:error, reason} ->
        {:error, message: "Sign In failed", details: Cambiatus.Error.from(reason)}

      {:ok, user} ->
        {:ok, %{user: user, token: CambiatusWeb.AuthToken.sign(user)}}
    end
  end

  def sign_in(_, _, _) do
    {:error,
     message: "Couldn't signIn, domain or invitation required",
     details: Cambiatus.Error.from("Error")}
  end

  def gen_auth(_, %{account: account}, %{context: %{domain: domain}}) do
    case Auth.create_request(account, domain) do
      {:error, reason} ->
        {:error, message: "Failed to create request", details: Cambiatus.Error.from(reason)}

      {:ok, request} ->
        {:ok, %{phrase: request.phrase}}
    end
  end

  def sign_up(_, args, %{context: %{domain: domain}}) do
    args
    |> Map.merge(%{domain: domain})
    |> SignUp.sign_up()
    |> case do
      {:error, reason, details} ->
        Sentry.capture_message("Sign up failed", extra: %{error: reason, details: details})
        {:error, message: reason, details: details}

      {:error, reason} ->
        Sentry.capture_message("Sign up failed", extra: %{error: reason})
        {:error, message: "Couldn't create user", details: Cambiatus.Error.from(reason)}

      {:ok, user} when not is_nil(user) ->
        {:ok, %{user: user, token: CambiatusWeb.AuthToken.sign(user)}}
    end
  end

  def sign_up(_, _, _) do
    {:error,
     message: "Couldn't create user, domain or invitation required",
     details: Cambiatus.Error.from("Error")}
  end

  @doc """
  Collects transfers belonging to the given user according various criteria, provided in `args`.
  """
  @spec get_transfers(map(), map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%User{} = user, args, _) do
    # Default query, sorted and with current user as participant
    query =
      Transfer
      |> Transfer.with_user(user.account)

    query =
      if Map.has_key?(args, :filter) do
        args
        |> Map.get(:filter)
        |> Enum.reduce(query, fn
          {:date, date}, query ->
            Transfer.on_day(query, date)

          {:direction, direction}, query ->
            Enum.reduce(direction, query, fn
              {:direction, :receiving}, query ->
                Transfer.received_by(query, user.account)

              {:direction, :sending}, query ->
                Transfer.sent_by(query, user.account)

              {:other_account, another_account}, query ->
                if Map.has_key?(direction, :direction) do
                  case Map.get(direction, :direction) do
                    :receiving ->
                      Transfer.sent_by(query, another_account)

                    :sending ->
                      Transfer.received_by(query, another_account)
                  end
                else
                  Transfer.with_user(another_account)
                end
            end)

          {:community_id, community_id}, query ->
            Transfer.on_community(query, community_id)
        end)
      else
        query
      end

    count = Transfer.count(query)

    query
    # Add sorting after counting
    |> Transfer.newer_first()
    |> Connection.from_query(&Cambiatus.Repo.all/1, args)
    |> case do
      {:ok, result} ->
        {:ok, Map.put(result, :count, Cambiatus.Repo.one(count))}

      default ->
        default
    end
  end

  def get_analysis_count(%User{} = user, _, _) do
    Accounts.get_analysis_count(user)
  end

  def get_contribution_count(%User{} = user, %{community_id: community_id}, _) do
    Accounts.get_contribution_count(user, community_id)
  end

  def get_contribution_count(%User{} = user, _, _) do
    Accounts.get_contribution_count(user)
  end
end
