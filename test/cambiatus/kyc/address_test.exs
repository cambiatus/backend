defmodule Cambiatus.Kyc.AddressTest do
  use Cambiatus.DataCase

  alias Cambiatus.Kyc.Address

  test "changeset is fine with correct data" do
    address = insert(:address) |> Cambiatus.Repo.preload(:country)
    assert(Address.changeset(address, %{}).valid?)
  end

  test "changeset is invalid with non existing country country" do
    address = insert(:address)
    changeset = Address.changeset(address, %{country_id: 2})
    refute(changeset.valid?)
    assert(Map.get(changeset, :errors) == [country_id: {"Country not found", []}])
  end

  test "changeset is invalid with unsupported country" do
    address_2 = insert(:address)
    new_country = insert(:country)
    changeset_2 = Address.changeset(address_2, %{country_id: new_country.id})
    refute(changeset_2.valid?)
    assert(Map.get(changeset_2, :errors) == [country_id: {"We only support 'Costa Rica'", []}])
  end

  test "changeset is invalid with invalid zip code" do
    address = insert(:address)
    changeset = Address.changeset(address, %{zip: "not a zip code"})
    refute(changeset.valid?)
    assert(Map.get(changeset, :errors) == [zip: {"Invalid Zip Code", []}])
  end

  test "changeset is invalid wth the wrong state" do
    address = build(:address)
    changeset = Address.changeset(%Address{}, Map.put(address, :state_id, 999))

    refute(changeset.valid?)
    # assert(Map.get(changeset, :errors) == [state_id: {"is invalid", []}])
  end

  test "changeset is invalid wth the wrong city" do
    assert false
  end

  test "changeset is invalid with the wrong neighborhood" do
    assert false
  end
end
