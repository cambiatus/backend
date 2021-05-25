defmodule CambiatusWeb.Schema.PaymentTypes do
  @moduledoc """
  GraphQL objects related to payments on Cambiatus
  """

  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  @desc ""
  object(:payment_queries) do
  end
end
