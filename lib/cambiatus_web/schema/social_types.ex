defmodule CambiatusWeb.Schema.SocialTypes do
  @moduledoc """
  This module holds objects, input objects, mutations and queries used with the `Cambiatus.Social` context
  use it to define entities to be used with the Social Context
  """
  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :classic

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]


  @desc "A news on Cambiatus"
  object :news do
    field(:title, non_null(:string))
    field(:description, non_null(:string))
    field(:scheduling, :datetime)
    field(:user, non_null(:user))
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
  end

  object :news_receipt do
    field(:reaction, non_null(list_of(non_null(:string))))
    field(:user, non_null(:user))
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
  end
end
