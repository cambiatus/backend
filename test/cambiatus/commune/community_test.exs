defmodule Cambiatus.Commune.CommunityTest do
  @moduledoc """
  This module holds unit tests to test drive community changesets
  """
  use Cambiatus.DataCase

  alias Cambiatus.{
    Commune,
    Commune.Community
  }

  describe "Community Changeset " do
    test "change_community/1 returns a community changeset" do
      community = insert(:community)
      assert %Ecto.Changeset{} = Commune.change_community(community)
    end

    test "create a valid community changeset with empty values" do
      params = %{
        description: "",
        logo: "",
        type: "",
        supply: nil,
        max_supply: nil,
        min_balance: nil,
        issuer: "",
        website: "",
        auto_invite: nil,
        has_objectives: nil,
        has_shop: nil,
        has_kyc: nil,
        highlighted_news: nil
      }

      changeset =
        build(:community, params)
        |> Community.changeset(%{})

      assert true == changeset.valid?
      assert [] == changeset.errors
    end
  end
end
