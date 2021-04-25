defmodule Cambiatus.Auth.Session do
  @moduledoc "Cambiatus Account Authentication and Signup Manager"

  # @valid_token 2 * 24 * 3600
  @valid_token 300

  alias CambiatusWeb.AuthToken
  alias Cambiatus.Auth.UserToken

  alias Cambiatus.{
    Accounts,
    Accounts.User,
    Repo,
    Auth.Ecdsa,
    Auth.Phrase
  }

  def create_phrase(user, user_agent) do
    phrase = Phrase.generate()

    %UserToken{}
    |> UserToken.changeset(%{phrase: phrase, context: "auth", user_agent: user_agent}, user)
    |> Repo.insert()
    |> case do
      {:ok, _} ->
        {:ok, phrase}

      {:error, _err} ->
        existing_auth = get_auth(user_id: user.account, user_agent: user_agent)
        {:ok, existing_auth.phrase}
    end
  end

  def verify_session_token(token) do
    with %UserToken{} = user_token <- get_session(token: token),
         {:ok, %{account: account}} <- AuthToken.verify(user_token.token, @valid_token) do
      %{user: Cambiatus.Accounts.get_user(account), token: token}
    else
      {:error, _} ->
        delete_session(token: token)
        {:error, "Invalid session"}

      nil ->
        {:error, "Session not found"}
    end
  end

  def verify_signature_helper(nil, _phrase, _signature, _user_agent),
    do: {:error, "No phrase found"}

  def verify_signature_helper(%{user_id: account}, phrase, signature, user_agent) do
    with true <- Ecdsa.verify_signature(account, signature, phrase),
         %User{} = user <- Accounts.get_user(account),
         %{token: token} <- create_session(user, user_agent) do
      delete_auth(phrase: phrase)
      {:ok, {user, token}}
    else
      false -> {:error, "Invalid signature"}
      nil -> {:error, "Account not found"}
      {:error, _} -> {:error, "Session can not be created"}
    end
  end

  def create_session({:error, _} = err), do: err

  def create_session(user, user_agent) do
    token = AuthToken.gen_token(%{account: user.account, user_agent: user_agent})

    %UserToken{}
    |> UserToken.changeset(%{token: token, context: "session", user_agent: user_agent}, user)
    |> Repo.insert()
    |> case do
      {:ok, data} ->
        data

      {:error, _} ->
        exist_session = get_session(user_agent: user_agent, user_id: user.account)

        verify_session_token(exist_session.token)
    end
  end

  def get_session(filter) do
    filter
    |> UserToken.with_session()
    |> Repo.one()
  end

  def get_all_session(filter) do
    filter
    |> UserToken.with_session()
    |> Repo.all()
  end

  def get_auth(filter) do
    filter
    |> UserToken.with_auth()
    |> Repo.one()
  end

  def delete_session(filter) do
    filter
    |> UserToken.with_session()
    |> Repo.one!()
    |> Repo.delete()
  end

  def delete_auth(filter) do
    filter
    |> UserToken.with_auth()
    |> Repo.one!()
    |> Repo.delete()
  end

  def delete_all_session(filter) do
    filter
    |> UserToken.with_session()
    |> Repo.delete_all()
  end

  def delete_all_auth(filter) do
    filter
    |> UserToken.with_auth()
    |> Repo.delete_all()
  end
end
