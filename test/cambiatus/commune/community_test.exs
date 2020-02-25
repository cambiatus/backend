defmodule Cambiatus.Commune.CommunityTest do
  @moduledoc """
  This module holds unit tests to test drive community changesets
  """
  use Cambiatus.DataCase

  alias Cambiatus.{
    Commune
  }

  describe "Community Changeset " do
    test "change_community/1 returns a community changeset" do
      community = insert(:community)
      assert %Ecto.Changeset{} = Commune.change_community(community)
    end
  end
end
