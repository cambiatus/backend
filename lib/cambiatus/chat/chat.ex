defmodule Cambiatus.Chat do
  @moduledoc "Cambiatus Chat manager"

  alias Cambiatus.Accounts.User
  alias Cambiatus.Validator

  @chat_api Application.get_env(:cambiatus, :chat_api)

  @doc """
  Based on an %User{} resource, try to log in to an account on Chat server,
  if account doesn't exist, it creates a new one and log in again.

  Examples:
  Cambiatus.Chat.sign_up(%Cambiatus.Accounts.User{account: "user1", email: "user1@email.com"})
  """
  @spec sign_in_or_up(User.t()) :: {:ok, User.t()} | {:error, term}
  def sign_in_or_up(user) do
    case sign_in(user) do
      {:ok, user} ->
        {:ok, user}

      {:error, :chat_signin_unauthorized} ->
        with {:ok, user} <- sign_up(user),
             {:ok, user} <- sign_in(user) do
          {:ok, user}
        else
          {:error, _} = error ->
            error

          _ ->
            {:error, :chat_unknown_error}
        end

      {:error, _} = error ->
        error

      _ ->
        {:error, :chat_signin_unknown_error}
    end
  end

  @doc """
  Based on an %User{} resource, log in to an account on Chat server.

  Examples:
  Cambiatus.Chat.sign_in(%Cambiatus.Accounts.User{account: "user1"})
  """
  @spec sign_in(User.t()) :: {:ok, User.t()} | {:error, term}
  def sign_in(%User{account: account} = user) do
    password = :crypto.hash(:sha256, account) |> Base.encode64()
    body = %{username: account, password: password}

    with {:ok, body} <- @chat_api.login(body),
         %{"status" => "success", "data" => data} <- body,
         %{"userId" => user_id, "authToken" => auth_token} <- data do
      {:ok, %User{user | chat_user_id: user_id, chat_token: auth_token}}
    else
      {:error, :bad_request} ->
        {:error, :chat_signin_bad_request}

      {:error, :unauthorized} ->
        {:error, :chat_signin_unauthorized}

      _ ->
        {:error, :chat_signin_unknown_error}
    end
  end

  @doc """
  Based on an %User{} resource, register an account on Chat server.

  Examples:
  Cambiatus.Chat.sign_up(%Cambiatus.Accounts.User{account: "user1", email: "user1@email.com"})
  """
  @spec sign_up(User.t()) :: {:ok, User.t()} | {:error, term}
  def sign_up(%User{account: account, email: email} = user) do
    password = :crypto.hash(:sha256, account) |> Base.encode64()

    email =
      case Validator.is_email?(email) do
        true ->
          email

        false ->
          account <> "@invalidemail.com"
      end

    body = %{
      username: account,
      email: email,
      password: password,
      name: account
    }

    case @chat_api.register(body) do
      {:ok, %{"success" => true}} ->
        {:ok, user}

      {:error, :bad_request} ->
        {:error, :chat_signup_bad_request}

      {:error, :unauthorized} ->
        {:error, :chat_signup_unauthorized}

      _ ->
        {:error, :chat_signup_unknown_error}
    end
  end

  @doc """
  From user_id and token, get all user's preferences

  Examples:
  Cambiatus.Chat.get_preferences(%{"user_id" => "any_user_id", "token" => "valid_token"})
  """
  @spec get_preferences(%{user_id: String.t(), token: String.t()}) ::
          {:ok, map()} | {:error, term()}
  def get_preferences(%{user_id: user_id, token: _} = params) do
    with {:ok, body} <- @chat_api.get_preferences(params),
         %{"success" => true, "preferences" => preferences} <- body,
         %{"language" => language} <- preferences do
      {:ok, %{user_id: user_id, language: language}}
    else
      {:error, :unauthorized} = error ->
        error

      {:error, :bad_request} ->
        {:ok, %{user_id: user_id, language: ""}}

      %{} ->
        {:ok, %{user_id: user_id, language: ""}}

      _ ->
        {:error, :unknown_error}
    end
  end

  @doc """
  From user_id and language, change preferred language in Chat server

  Examples:
  Cambiatus.Chat.change_language(%{"user_id" => "any_user_id", "language" => "language_in_iso_format"})
  """
  @spec update_language(%{user_id: String.t(), language: String.t()}) ::
          {:ok, map()} | {:error, term()}
  def update_language(%{user_id: _, language: _} = params) do
    with {:ok, body} <- @chat_api.update_language(params),
         %{"success" => true, "user" => user} <- body,
         %{"_id" => user_id, "settings" => %{"preferences" => %{"language" => language}}} <- user do
      {:ok, %{user_id: user_id, language: language}}
    else
      {:error, :unauthorized} = error ->
        error

      {:error, :bad_request} = error ->
        error

      _ ->
        {:error, :unknown_error}
    end
  end
end
