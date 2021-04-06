defmodule CambiatusWeb.Plugs.GetToken do
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
    conn
    |> get_req_header("authorization")
    |> case do
      ["Bearer " <> token] ->
        %{token: token}

      [] ->
        %{}
    end
  end
end
