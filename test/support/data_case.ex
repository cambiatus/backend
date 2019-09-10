defmodule BeSpiral.DataCase do
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
      alias BeSpiral.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import BeSpiral.DataCase
      import BeSpiral.Factory
    end
  end

  setup tags do
    :ok = Sandbox.checkout(BeSpiral.Repo)

    unless tags[:async] do
      Sandbox.mode(BeSpiral.Repo, {:shared, self()})
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
      issuer: "bespiraltest",
      creator: "testtesttest",
      name: "BeSpiral",
      description: "Default test community",
      supply: 10.0,
      max_supply: 100.0,
      min_balance: -100.0,
      inviter_reward: 0.0,
      invited_reward: 0.0,
      allow_subcommunity: true,
      subcommunity_price: 0.0
    }

    {:ok, community} = BeSpiral.Commune.create_community(community_params)

    root_params = %{
      account: "bespiraltest"
    }

    {:ok, root} = BeSpiral.Accounts.create_user(root_params)

    user_params = %{
      account: "testtesttest",
      name: "Test User 1",
      email: "test_user_1@email.com"
    }

    {:ok, user} = BeSpiral.Accounts.create_user(user_params)

    another_user_params = %{
      account: "anothertest1",
      name: "Test User 2",
      email: "test_user_2@email.com"
    }

    {:ok, another_user} = BeSpiral.Accounts.create_user(another_user_params)

    user_chat_success_params = %{
      user_id: "user_id",
      account: "success",
      email: "",
      token: "success",
      language: "pt-BR"
    }

    user_chat_bad_request_params = %{
      user_id: "user_id",
      account: "bad_request",
      email: "",
      token: "bad_request",
      language: "bad_request"
    }

    user_chat_unauthorized_params = %{
      user_id: "user_id",
      account: "unauthorized",
      email: "",
      token: "unauthorized",
      language: "unauthorized"
    }

    user_chat_unknown_params = %{
      user_id: "unknown",
      account: "",
      email: "",
      token: "",
      language: ""
    }

    %{
      community: community,
      user: user,
      another_user: another_user,
      bespiral_account: root,
      user_chat_success: user_chat_success_params,
      user_chat_bad_request: user_chat_bad_request_params,
      user_chat_unauthorized: user_chat_unauthorized_params,
      user_chat_unknown: user_chat_unknown_params
    }
  end

  def invitation(_context) do
    BeSpiral.Auth.create_invitation()
  end
end
