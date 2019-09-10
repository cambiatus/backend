defmodule BeSpiral.Notifications.PushSubscriptionTest do
  @moduledoc """
  Unit tests to test drive `BeSpiral.Notifications.PushSubscription changeset functions
  """
  use BeSpiral.DataCase
  import BeSpiral.Factory

  alias BeSpiral.{
    Notifications.PushSubscription
  }

  describe "Notification changesets" do
    test "create_changeset/2 creates a valid changeset with valid params" do
      user = insert(:user)

      params = %{
        auth_key: "long-random-key",
        p_key: "some-long-private-hash",
        endpoint: "user-agent-endpoint"
      }

      changeset = PushSubscription.create_changeset(user, params)

      assert changeset.valid?
    end

    test "create_changeset/2 returns an invalid changeset with wrong params" do
      user = insert(:user)

      changeset = PushSubscription.create_changeset(user, %{})

      refute changeset.valid?
    end
  end
end
