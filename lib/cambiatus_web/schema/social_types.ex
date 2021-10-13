defmodule CambiatusWeb.Schema.SocialTypes do
  @moduledoc """
  This module holds objects, input objects, mutations and queries used with the `Cambiatus.Social` context
  use it to define entities to be used with the Social Context
  """
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic

  alias CambiatusWeb.Resolvers.Social
  alias CambiatusWeb.Schema.Middleware

  @desc "News data mutations"
  object :social_mutations do
    @desc "[Auth required] News mutation, that allows for creating and updating news on a community"
    field :news, :news do
      arg(:title, non_null(:string))
      arg(:description, non_null(:string))
      arg(:community_id, non_null(:string))
      arg(:scheduling, :datetime)

      middleware(Middleware.Authenticate)
      resolve(&Social.news/3)
    end

    @desc "[Auth required] News mutation, that allows for creating and updating news on a community"
    field :upsert_news_receipt, :news_receipt do
      arg(:news_id, non_null(:integer))
      arg(:reactions, list_of(non_null(:string)))

      middleware(Middleware.Authenticate)
      resolve(&Social.upsert_news_receipt/3)
    end
  end

  @desc "A news on Cambiatus"
  object :news do
    field(:id, non_null(:integer))
    field(:title, non_null(:string))
    field(:description, non_null(:string))
    field(:scheduling, :datetime)
    field(:user, non_null(:user))
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
  end

  object :news_receipt do
    field(:reactions, non_null(list_of(non_null(:string))))
    field(:user, non_null(:user))
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
  end
end
