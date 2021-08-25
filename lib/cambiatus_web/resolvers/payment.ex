defmodule CambiatusWeb.Resolvers.Payment do
  @moduledoc """
  Module that holds resolvers related to payment entities
  """

  alias Cambiatus.Payments

  def create_contribution(_, params, %{context: current_user}) do
    Payments.create_contribution(Map.merge(params, %{user: current_user}))
  end
end
