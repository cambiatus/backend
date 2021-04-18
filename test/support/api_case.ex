defmodule Cambiatus.ApiCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.
  You may define functions here to be used as helpers in
  your tests.
  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  alias Ecto.Adapters.SQL.Sandbox

  use ExUnit.CaseTemplate
  use Phoenix.ConnTest

  using do
    quote do
      use Phoenix.ConnTest
      alias Cambiatus.Repo
      alias Cambiatus.Auth

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Cambiatus.Factory

      @endpoint CambiatusWeb.Endpoint

      defp auth_user(conn, user) do
        token = Auth.create_session(user)
        put_req_header(conn, "authorization", "Bearer #{token}")
      end
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Cambiatus.Repo)

    unless tags[:async] do
      Sandbox.mode(Cambiatus.Repo, {:shared, self()})
    end

    {:ok, conn: build_conn()}
  end
end
