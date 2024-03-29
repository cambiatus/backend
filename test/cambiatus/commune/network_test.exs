defmodule Cambiatus.Commune.NetworkTest do
  @moduledoc """
  Unit tests to test drive network changesets
  """
  use Cambiatus.DataCase

  alias Cambiatus.Commune

  describe "Network Changesets" do
    setup :valid_community_and_user

    test "change_network/1 returns a network changeset", %{
      user: user,
      another_user: another_user
    } do
      community = insert(:community)
      network = insert(:network, %{user: another_user, community: community, invited_by: user})

      assert %Ecto.Changeset{} = Commune.change_network(network)
    end
  end
end
