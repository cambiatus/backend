defmodule CambiatusWeb.SubscriptionCase do
  @moduledoc """
  A test case for testing Absinter Subscriptions
  """

  use ExUnit.CaseTemplate
  import Phoenix.ChannelTest

  @endpoint CambiatusWeb.Endpoint
  alias CambiatusWeb.UserSocket

  using do
    quote do
      use Phoenix.ChannelTest

      use Absinthe.Phoenix.SubscriptionTest,
        schema: CambiatusWeb.Schema

      @endpoint CambiatusWeb.Endpoint

      import Cambiatus.Factory
      alias Cambiatus.Repo
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Cambiatus.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Cambiatus.Repo, {:shared, self()})
    end

    {:ok, socket} = Phoenix.ChannelTest.connect(UserSocket, %{})

    {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)

    {:ok, socket: socket}
  end
end
