defmodule Cambiatus.KycDataTest do
  use Cambiatus.DataCase

  alias Cambiatus.Kyc.KycData

  test "changeset is fine with valid kyc data" do
    kyc = insert(:kyc_data)
    changeset = KycData.changeset(kyc, %{})
    assert(Map.get(changeset, :errors) == [])
    assert(changeset.valid?)
  end

  test "changeset is invalid without required data" do
    user = insert(:user)
    data = %{account_id: user.account, document: ""}

    changeset = KycData.changeset(%KycData{}, data)
    refute(changeset.valid?)
  end

  test "changeset is invalid with wrong user_type" do
    kyc = insert(:kyc_data)

    data = %{
      account_id: kyc.account_id,
      user_type: "not valid user type",
      document: kyc.document,
      document_type: kyc.document_type,
      phone: kyc.phone,
      country_id: kyc.country_id
    }

    changeset = KycData.changeset(%KycData{}, data)
    refute(changeset.valid?)

    assert(
      Map.get(changeset, :errors) == [
        user_type: {"is invalid", []}
      ]
    )
  end

  test "changeset is invalid with wrong document_type" do
    kyc = insert(:kyc_data)

    data = %{
      account_id: kyc.account_id,
      user_type: kyc.user_type,
      document: "somedocument",
      document_type: "not valid document type",
      phone: kyc.phone,
      country_id: kyc.country_id
    }

    changeset = KycData.changeset(%KycData{}, data)
    refute(changeset.valid?)
    assert(Map.get(changeset, :errors) == [document_type: {"is invalid", []}])
  end

  test "changeset is invalid with regular user, using `cedula de identidade`, with invalid document" do
    kyc = insert(:kyc_data)

    data = %{
      account_id: kyc.account_id,
      user_type: "natural",
      document: "088888888",
      document_type: "cedula_de_identidad",
      phone: kyc.phone,
      country_id: kyc.country_id
    }

    changeset = KycData.changeset(%KycData{}, data)
    refute(changeset.valid?)
    assert(Map.get(changeset, :errors) == [document: {"is invalid for cedula_de_identidad", []}])
  end

  test "changeset is invalid with regular user, using `dimex`, with invalid document" do
    kyc = insert(:kyc_data)

    data = %{
      account_id: kyc.account_id,
      user_type: "natural",
      document: "088888",
      document_type: "dimex",
      phone: kyc.phone,
      country_id: kyc.country_id
    }

    changeset = KycData.changeset(%KycData{}, data)
    refute(changeset.valid?)
    assert(Map.get(changeset, :errors) == [document: {"is invalid for dimex", []}])
  end

  test "changeset is invalid with regular user, using `nite`, with invalid document" do
    kyc = insert(:kyc_data)

    data = %{
      account_id: kyc.account_id,
      user_type: "natural",
      document: "088888",
      document_type: "nite",
      phone: kyc.phone,
      country_id: kyc.country_id
    }

    changeset = KycData.changeset(%KycData{}, data)
    refute(changeset.valid?)
    assert(Map.get(changeset, :errors) == [document: {"is invalid for nite", []}])
  end

  test "changeset is invalid with company user, using `mipyme`, with invalid document" do
    kyc = insert(:kyc_data)

    data = %{
      account_id: kyc.account_id,
      user_type: "juridical",
      document: "088888",
      document_type: "mipyme",
      phone: kyc.phone,
      country_id: kyc.country_id
    }

    changeset = KycData.changeset(%KycData{}, data)
    refute(changeset.valid?)
    assert(Map.get(changeset, :errors) == [document: {"is invalid for mipyme", []}])
  end

  test "changeset is invalid with company user, using `gran empresa`, with invalid document" do
    kyc = insert(:kyc_data)

    data = %{
      account_id: kyc.account_id,
      user_type: "juridical",
      document: "088888",
      document_type: "gran_empresa",
      phone: kyc.phone,
      country_id: kyc.country_id
    }

    changeset = KycData.changeset(%KycData{}, data)
    refute(changeset.valid?)
    assert(Map.get(changeset, :errors) == [document: {"is invalid for gran_empresa", []}])
  end
end
