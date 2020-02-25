defmodule CambiatusWeb.Schema.ChatTypes do
  @moduledoc """
  This module holds objects, input objects, mutations and queries used with the Chat context in `Cambiatus`
  use it to define entities to be used with the Chat Context
  """
  use Absinthe.Schema.Notation

  alias CambiatusWeb.Resolvers.Chat

  @desc "Chat Queries"
  object :chat_queries do
    @desc "A chat preferences"
    field :chat_preferences, :chat_preferences do
      arg(:input, non_null(:chat_input))
      resolve(&Chat.get_preferences/3)
    end
  end

  @desc "Chat Mutations"
  object :chat_mutations do
    @desc "A mutation to update user's chat language"
    field :update_chat_language, :chat_preferences do
      arg(:input, non_null(:chat_update_input))
      resolve(&Chat.update_language/3)
    end
  end

  @desc "Input Object for fetching a User's Chat Preferences"
  input_object :chat_input do
    field(:user_id, non_null(:string))
    field(:token, non_null(:string))
  end

  @desc "Input Object for update a User's Chat Language"
  input_object :chat_update_input do
    field(:user_id, non_null(:string))
    field(:language, non_null(:string))
  end

  @desc "User's Chat Preferences"
  object :chat_preferences do
    field(:user_id, non_null(:string))
    field(:language, non_null(:string))
  end
end
