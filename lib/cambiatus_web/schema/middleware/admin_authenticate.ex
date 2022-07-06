defmodule CambiatusWeb.Schema.Middleware.AdminAuthenticate do
  @moduledoc """
  Absinthe Middleware that checks if user is an admin of the current community, based on the Domain inside our context
  """

  @behaviour Absinthe.Middleware

  alias Cambiatus.Commune

  def call(resolution, _) do
    case resolution.context do
      %{current_user: user, domain: domain} ->
        {:ok, community} = Commune.get_community_by_subdomain(domain)

        if Commune.is_community_admin?(community, user.account) do
          resolution
        else
          resolution
          |> Absinthe.Resolution.put_result({:error, "Logged user isn't an admin"})
        end
    end
  end
end
