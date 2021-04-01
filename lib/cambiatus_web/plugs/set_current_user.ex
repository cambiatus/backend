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
    context_user = set_user(conn)
    context_phrase = set_phrase(conn)
    context = Map.merge(context_user, context_phrase)
    Absinthe.Plug.put_options(conn, context: context)
  end

  def set_user(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
         {:ok, %{id: account}} <- AuthToken.verify(token),
         %{} = user <- Cambiatus.Accounts.get_user(account) do
      %{current_user: user}
    else
      _ -> %{}
    end
  end

  def set_phrase(conn) do
    get_req_header(conn, "authorization")
    |> case do
      ["Bearer " <> token] ->
        AuthToken.get_phrase(token)
        |> case do
          {:ok, data} ->
            data |> Map.put(:token, token)

          _ ->
            %{}
        end

      [] ->
        %{}
    end
  end
end
