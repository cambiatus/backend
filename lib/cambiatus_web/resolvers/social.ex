defmodule CambiatusWeb.Resolvers.Social do
  @moduledoc """
  This module holds the implementation of the resolver for the Social context
  use this to resolve any queries and mutations for Social
  """

  alias Cambiatus.Social

  def news(_, params, %{context: %{current_user: current_user}}) do
    params
    |> Map.merge(%{user_id: current_user.account})
    |> Social.create_news()
    |> case do
      {:error, reason} ->
        Sentry.capture_message("News creation failed", extra: %{error: reason})
        {:error, message: "Could not create news", details: Cambiatus.Error.from(reason)}

      {:ok, news} ->
        {:ok, news}
    end
  end
end
