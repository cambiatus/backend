defmodule CambiatusWeb.Resolvers.Chat do
  @moduledoc """
  This module holds the implementation of the resolver for the Chat context
  use this to resolve any queries and mutations for Chats
  """

  alias Cambiatus.Chat

  @doc """
  Get user's chat preferences
  """
  @spec get_preferences(map(), %{input: %{user_id: String.t(), token: String.t()}}, map()) ::
          {:ok, map()} | {:error, term()}
  def get_preferences(_root, %{input: %{user_id: _, token: _} = input}, _info) do
    Chat.get_preferences(input)
  end

  @doc """
  Update user's chat language
  """
  @spec update_language(map(), %{input: %{user_id: String.t(), language: String.t()}}, map()) ::
          {:ok, map()} | {:error, term()}
  def update_language(_root, %{input: %{user_id: _, language: _} = input}, _info) do
    Chat.update_language(input)
  end
end
