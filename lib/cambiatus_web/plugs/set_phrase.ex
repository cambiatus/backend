defmodule CambiatusWeb.Plugs.SetPhrase do
  @moduledoc """
  Plug used together with GraphQL to quickly add the current logged user on the resolvers data

  This allows to get the user based on the token sent as Authorization header
  """

  @behaviour Plug

  import Plug.Conn

  alias CambiatusWeb.AuthToken

  def init(opts), do: opts

  def call(conn, _) do
    context = build_context(conn)
    Absinthe.Plug.put_options(conn, context: context)
  end

  def build_context(conn) do
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

    # with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
    #      {:ok, data} <- AuthToken.get_phrase(token) do
    #   data
    # else
    #   _ ->
    #     AuthToken.invalidate(token)
    #     %{}
    # end
  end
end
