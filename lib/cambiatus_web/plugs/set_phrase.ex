defmodule CambiatusWeb.Plugs.SetPhrase do
  @moduledoc """
  Plug used together with GraphQL to quickly add the current logged user on the resolvers data

  This allows to get the user based on the token sent as Authorization header
  """

  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    context = conn |> get_phrase() |> update_context()
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp get_phrase(conn) do
    conn
    |> fetch_session()
    |> get_session(:phrase)
    |> case do
      nil -> {conn, %{}}
      phrase -> {conn, %{phrase: phrase}}
    end
  end

  defp update_context({conn, context}) do
    context
    |> Map.merge(conn.private[:absinthe].context)
  end
end
