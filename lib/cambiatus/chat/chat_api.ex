defmodule Cambiatus.Chat.Api do
  @moduledoc false

  @doc """
  Make a request to log in to an account on Chat server.
  """
  @callback login(%{username: String.t(), password: String.t()}) ::
              {:ok, map()} | {:error, term()}

  @doc """
  Make a request to create an account on Chat server.
  """
  @callback register(%{
              username: String.t(),
              email: String.t(),
              password: String.t(),
              name: String.t()
            }) :: {:ok, map()} | {:error, term()}

  @doc """
  Make a request to get chat user's preferences
  """
  @callback get_preferences(%{user_id: String.t(), token: String.t()}) ::
              {:ok, map()} | {:error, term()}

  @doc """
  Make a request to change user's preferred language
  """
  @callback update_language(%{user_id: String.t(), language: String.t()}) ::
              {:ok, map()} | {:error, term()}
end
