defmodule CambiatusWeb.Resolvers.Payment do
  @moduledoc """
  Module that holds resolvers related to payment entities
  """

  alias Cambiatus.Payments

  def create_contribution(_, params, %{
        context: %{current_user: current_user, current_community: current_community}
      }) do
    params
    |> Map.merge(%{user_id: current_user.account, community_id: current_community.symbol})
    |> Payments.create_contribution()
    |> case do
      {:ok, _} = success ->
        success

      {:error, changeset} ->
        {:error,
         message: "Couldn't create contribution", details: Cambiatus.Error.from(changeset)}
    end
  end
end
