defmodule CambiatusWeb.Schema.Middleware.AdminAuthenticate do
  @moduledoc """
  Absinthe Middleware that checks if user is an admin of the current community, based on the Domain inside our context
  """

  @behaviour Absinthe.Middleware

  alias Cambiatus.Commune

  def call(
        %{context: %{current_user: current_user, current_community: current_community}} =
          resolution,
        _
      ) do
    if Commune.is_community_admin?(current_community, current_user.account) do
      resolution
    else
      resolution
      |> Absinthe.Resolution.put_result({:error, "Logged user isn't an admin"})
    end
  end
end
