defmodule CambiatusWeb.Plugs.SetPhrase do
  @moduledoc """
  Set phrase and user agent in context
  """

  @behaviour Plug

  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _) do
    context = conn |> get_auth() |> set_user_agent() |> update_context()
    Absinthe.Plug.put_options(conn, context: context)
  end

  defp get_auth(conn) do
    conn
    |> fetch_session()
    |> get_session(:phrase)
    |> case do
      nil -> {conn, %{}}
      phrase -> {conn, %{phrase: phrase}}
    end
  end

  defp set_user_agent({conn, context}) do
    user_agent = conn |> get_req_header("user-agent") |> hd
    updated_context = context |> Map.put(:user_agent, user_agent)
    {conn, updated_context}
  end

  defp update_context({conn, context}) do
    context
    |> Map.merge(conn.private[:absinthe].context)
  end
end
