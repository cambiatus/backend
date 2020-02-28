defmodule Cambiatus.DataCase do
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

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias Cambiatus.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Cambiatus.DataCase
      import Cambiatus.Factory
    end
  end

  setup tags do
    :ok = Sandbox.checkout(Cambiatus.Repo)

    unless tags[:async] do
      Sandbox.mode(Cambiatus.Repo, {:shared, self()})
    end

    :ok
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.
  assert {:error, changeset} = Accounts.create_user(%{password: "short"})
  assert "password is too short" in errors_on(changeset).password
  assert %{password: ["password is too short"]} = errors_on(changeset)
  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  def valid_community_and_user(_context) do
    community_params = %{
      symbol: "BES",
      issuer: "cambiatustest",
      creator: "testtesttest",
      name: "Cambiatus",
      description: "Default test community",
      supply: 10.0,
      max_supply: 100.0,
      min_balance: -100.0,
      inviter_reward: 0.0,
      invited_reward: 0.0,
      allow_subcommunity: true,
      subcommunity_price: 0.0
    }

    {:ok, community} = Cambiatus.Commune.create_community(community_params)

    {:ok, root} =
      Cambiatus.Accounts.create_user(%{
        account: "cambiatustest"
      })

    {:ok, user} =
      Cambiatus.Accounts.create_user(%{
        account: "testtesttest",
        name: "Test User 1",
        email: "test_user_1@email.com"
      })

    {:ok, another_user} =
      Cambiatus.Accounts.create_user(%{
        account: "anothertest1",
        name: "Test User 2",
        email: "test_user_2@email.com"
      })

    %{
      community: community,
      user: user,
      another_user: another_user,
      cambiatus_account: root
    }
  end

  def invitation(_context) do
    Cambiatus.Auth.create_invitation()
  end
end
