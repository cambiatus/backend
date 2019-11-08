defmodule BeSpiralWeb.SubscriptionCase do
  @moduledoc """
  A test case for testing Absinter Subscriptions 
  """

  use ExUnit.CaseTemplate
  use Phoenix.ChannelTest

  @endpoint BeSpiralWeb.Endpoint
  alias BeSpiralWeb.UserSocket

  using do
    quote do
      use Phoenix.ChannelTest

      use Absinthe.Phoenix.SubscriptionTest,
        schema: BeSpiralWeb.Schema

      @endpoint BeSpiralWeb.Endpoint

      import BeSpiral.Factory
      alias BeSpiral.Repo
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(BeSpiral.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(BeSpiral.Repo, {:shared, self()})
    end

    {:ok, socket} = Phoenix.ChannelTest.connect(UserSocket, %{})

    {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)

    {:ok, socket: socket}
  end
end
