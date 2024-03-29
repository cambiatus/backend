defmodule CambiatusWeb.Schema.SocialTypes do
  @moduledoc """
  This module holds objects, input objects, mutations and queries used with the `Cambiatus.Social` context
  use it to define entities to be used with the Social Context
  """
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias CambiatusWeb.Resolvers.Social
  alias CambiatusWeb.Schema.Middleware

  @desc "News query"
  object :social_queries do
    @desc "Get news"
    field(:news, :news) do
      arg(:news_id, non_null(:integer))

      resolve(&Social.get_news/3)
    end
  end

  @desc "News data mutations"
  object :social_mutations do
    @desc "[Auth required - Admin only] News mutation, that allows for creating news on a community"
    field :news, :news do
      arg(:id, :integer)
      arg(:title, non_null(:string))
      arg(:description, non_null(:string))
      arg(:scheduling, :datetime)

      middleware(Middleware.Authenticate)
      resolve(&Social.upsert_news/3)
    end

    @desc "[Auth required] Mark news as read, creating a new news_receipt without reactions"
    field :read, :news_receipt do
      arg(:news_id, non_null(:integer))

      middleware(Middleware.Authenticate)
      resolve(&Social.mark_news_as_read/3)
    end

    @desc "[Auth required] Add or update reactions from user in a news through news_receipt"
    field :react_to_news, :news_receipt do
      arg(:news_id, non_null(:integer))
      arg(:reactions, non_null(list_of(non_null(:reaction_enum))))

      middleware(Middleware.Authenticate)
      resolve(&Social.update_reactions/3)
    end

    @desc "[Auth required] Deletes News "
    field :delete_news, :delete_status do
      arg(:news_id, non_null(:integer))

      middleware(Middleware.Authenticate)
      resolve(&Social.delete_news/3)
    end
  end

  @desc "A news on Cambiatus"
  object :news do
    field(:id, non_null(:integer))
    field(:title, non_null(:string))
    field(:description, non_null(:string))
    field(:scheduling, :datetime)
    field(:user, non_null(:user), resolve: dataloader(Cambiatus.Accounts))
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
    field(:receipt, :news_receipt, resolve: &Social.get_news_receipt_from_user/3)

    field(:reactions, non_null(list_of(non_null(:reaction_type))),
      resolve: &Social.get_reactions/3
    )

    field(:versions, non_null(list_of(non_null(:news_version))),
      resolve: &Social.get_news_versions/3
    )
  end

  object :news_receipt do
    field(:reactions, non_null(list_of(non_null(:reaction_enum))))
    field(:user, non_null(:user), resolve: dataloader(Cambiatus.Accounts))
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
  end

  object :news_version do
    field(:title, non_null(:string))
    field(:description, non_null(:string))
    field(:scheduling, :datetime)
    field(:user, non_null(:user), resolve: dataloader(Cambiatus.Accounts))
  end

  object :reaction_type do
    field(:reaction, non_null(:reaction_enum))
    field(:count, non_null(:integer))
  end

  enum(:reaction_enum,
    values: [
      :grinning_face_with_big_eyes,
      :smiling_face_with_heart_eyes,
      :slightly_frowning_face,
      :face_with_raised_eyebrow,
      :thumbs_up,
      :thumbs_down,
      :clapping_hands,
      :party_popper,
      :red_heart,
      :rocket
    ]
  )
end
