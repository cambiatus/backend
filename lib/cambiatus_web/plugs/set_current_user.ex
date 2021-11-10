defmodule CambiatusWeb.Plugs.SetCurrentUser do
  @moduledoc """
  Plug used together with GraphQL to quickly add the current logged user on the resolvers data

  This allows to get the user based on the token sent as Authorization header
  """

  @behaviour Plug

  import Plug.Conn

  alias CambiatusWeb.AuthToken

  def init(opts), do: opts

  def call(conn, _) do
    context =
      set_current_user(conn)
      |> set_user_agent(conn)

    Absinthe.Plug.put_options(conn, context: context)
  end

  def set_current_user(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, %{id: account}} <- AuthToken.verify(token),
         %{} = user <- Cambiatus.Accounts.get_user(account) do
      %{current_user: user}
    else
      _ -> %{}
    end
  end

  def set_user_agent(context, conn) do
    case get_req_header(conn, "user-agent") do
      [agent] -> Map.put(context, :user_agent, agent)
      _ -> context
    end
  end
end
