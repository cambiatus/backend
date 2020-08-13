defmodule Cambiatus.KycTest do
  use Cambiatus.DataCase

  alias Cambiatus.Kyc

  test "changeset is fine with valid kyc data" do
    kyc = insert(:kyc)
    assert(Kyc.changeset(kyc, %{}).valid?)
  end

  test "changeset is invalid without required data" do
    user = insert(:user)
    data = %{account_id: user.account, document: ""}

    changeset = Kyc.changeset(%Kyc{}, data)
    refute(changeset.valid?)
  end

  test "changeset is invalid with wrong user_type" do
    kyc = insert(:kyc)

    data = %{
      account_id: kyc.account_id,
      user_type: "not valid user type",
      document: kyc.document,
      document_type: kyc.document_type,
      phone: kyc.phone,
      country_id: kyc.country_id
    }

    changeset = Kyc.changeset(%Kyc{}, data)
    refute(changeset.valid?)
    assert(Map.get(changeset, :errors) == [user_type: {"is invalid", []}])
  end

  test "changeset is invalid with wrong document_type" do
    kyc = insert(:kyc)

    data = %{
      account_id: kyc.account_id,
      user_type: kyc.user_type,
      document: kyc.document,
      document_type: "not valid document type",
      phone: kyc.phone,
      country_id: kyc.country_id
    }

    changeset = Kyc.changeset(%Kyc{}, data)
    refute(changeset.valid?)
    assert(Map.get(changeset, :errors) == [document_type: {"is invalid", []}])
  end

  test "changeset is invalid with regular user invalid document" do
    assert false
  end

  test "changeset is invalid with company user invalid document" do
    assert false
  end
end
