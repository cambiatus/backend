defmodule Cambiatus.PaymentsTest do
  use Cambiatus.DataCase

  alias Cambiatus.Payments

  describe "contributions" do
    test "list_contributions/0 returns all contributions" do
      contribution = insert(:contributions)
      {:ok, found_contributions} = Payments.list_contributions()

      assert [contribution] == found_contributions |> Repo.preload([:user, community: :subdomain])
    end
  end
end
