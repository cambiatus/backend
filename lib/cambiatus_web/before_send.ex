defmodule CambiatusWeb.BeforeSend do
  @moduledoc "Make any necessary changes prior to sending absinthe response"

  import Plug.Conn

  def absinthe_before_send(conn, %Absinthe.Blueprint{} = blueprint) do
    if phrase = blueprint.execution.context[:phrase] do
      conn
      |> fetch_session()
      |> put_session(:phrase, phrase)
    else
      conn
    end
  end

  def absinthe_before_send(conn, _) do
    conn
  end
end
