defmodule Cambiatus.Kyc.AddressTest do
  use Cambiatus.DataCase

  alias Cambiatus.Kyc.Address

  test "changeset is fine with correct data" do
    address = insert(:address) |> Cambiatus.Repo.preload(:country)
    assert(Address.changeset(address, %{}).valid?)
  end

  test "changeset is invalid with non existing country" do
    address = insert(:address)
    changeset = Address.changeset(address, %{country_id: 2})
    refute(changeset.valid?)

    assert(
      Map.get(changeset, :errors) ==
        [
          state_id: {"is invalid", []},
          country_id: {"Country not found", []}
        ]
    )
  end

  test "changeset is invalid with unsupported country" do
    address_2 = insert(:address)
    new_country = insert(:country, name: "Not Costa Rica")
    changeset_2 = Address.changeset(address_2, %{country_id: new_country.id})
    refute(changeset_2.valid?)

    assert(
      Map.get(changeset_2, :errors) == [
        state_id: {"don't belong to country", []}
      ]
    )
  end

  test "changeset is invalid with invalid zip code" do
    address = insert(:address)
    changeset = Address.changeset(address, %{zip: "not a zip code"})
    refute(changeset.valid?)
    assert(Map.get(changeset, :errors) == [zip: {"Invalid Zip Code", []}])
  end

  test "changeset is invalid with the wrong state" do
    address = build(:address)

    another_country = insert(:country, name: "Not Costa Rica")
    another_state = insert(:state, %{country: another_country})

    params = %{
      account_id: address.account.account,
      street: address.street,
      neighborhood_id: address.neighborhood_id,
      city_id: address.city_id,
      # Another state
      state_id: another_state.id,
      country_id: address.country_id,
      zip: address.zip,
      number: address.number
    }

    changeset = Address.changeset(%Address{}, params)

    refute(changeset.valid?)

    assert(
      Map.get(changeset, :errors) ==
        [
          city_id: {"don't belong to state", []},
          state_id: {"don't belong to country", []}
        ]
    )
  end

  test "changeset is invalid with the wrong city" do
    address = build(:address)

    another_country = insert(:country, name: "Brazil")
    another_state = insert(:state, %{country: another_country})
    another_city = insert(:city, %{state: another_state})

    params = %{
      account_id: address.account.account,
      street: address.street,
      neighborhood_id: address.neighborhood_id,
      # Another city
      city_id: another_city.id,
      state_id: address.state_id,
      country_id: address.country_id,
      zip: address.zip,
      number: address.number
    }

    changeset = Address.changeset(%Address{}, params)

    refute(changeset.valid?)

    assert(
      Map.get(changeset, :errors) == [
        neighborhood_id: {"don't belong to city", []},
        city_id: {"don't belong to state", []}
      ]
    )
  end

  test "changeset is invalid with the wrong neighborhood" do
    address = build(:address)

    another_country = insert(:country, name: "Another Country")
    another_state = insert(:state, %{country: another_country})
    another_city = insert(:city, %{state: another_state})
    another_neighborhood = insert(:neighborhood, %{city: another_city})

    params = %{
      account_id: address.account.account,
      street: address.street,
      # Another neighborhood
      neighborhood_id: another_neighborhood.id,
      city_id: address.city_id,
      state_id: address.state_id,
      country_id: address.country_id,
      zip: address.zip,
      number: address.number
    }

    changeset = Address.changeset(%Address{}, params)

    refute(changeset.valid?)
    assert(Map.get(changeset, :errors) == [neighborhood_id: {"don't belong to city", []}])
  end
end
