defmodule CambiatusWeb.Schema.Resolvers.KycTest do
  @moduledoc """
  Tests for resolvers for the Kyc context.
  """
  use Cambiatus.ApiCase

  describe "Kyc Resolver" do
    @zip "10102"
    @street "Elm Street"

    test "updates kyc data for the given account" do
      kyc = insert(:kyc_data)
      user = kyc.account

      conn = build_conn() |> auth_user(user)

      new_kyc = build(:kyc_data, %{account: nil})

      variables = %{
        "input" => %{
          "country_id" => "1",
          "phone" => new_kyc.phone,
          "user_type" => new_kyc.user_type,
          "document" => new_kyc.document,
          "document_type" => new_kyc.document_type
        }
      }

      query = """
      mutation ($input: KycDataUpdateInput!) {
        upsertKyc(input: $input) {
          document
          document_type
          phone
        }
      }
      """

      res = conn |> post("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "upsertKyc" => updated_kyc
        }
      } = json_response(res, 200)

      assert updated_kyc["document"] == new_kyc.document
      assert updated_kyc["document_type"] == new_kyc.document_type
      assert updated_kyc["phone"] == new_kyc.phone
    end

    test "updates address for the given account" do
      address = insert(:address)
      user = address.account
      conn = build_conn() |> auth_user(user)

      variables = %{
        "input" => %{
          "country_id" => "1",
          "state_id" => "1",
          "city_id" => "1",
          "neighborhood_id" => "1",
          "street" => @street,
          "number" => "11",
          "zip" => @zip
        }
      }

      query = """
      mutation ($input: AddressUpdateInput!) {
        upsertAddress(input: $input) {
          zip
          street
        }
      }
      """

      res = conn |> post("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "upsertAddress" => updated_address
        }
      } = json_response(res, 200)

      assert updated_address["zip"] == @zip
      assert updated_address["street"] == @street
    end

    test "creates an address and KYC for the given account name" do
      usr = insert(:user)
      new_kyc = build(:kyc_data, %{account: nil})

      conn = build_conn() |> auth_user(usr)

      variables = %{
        "inputAddress" => %{
          "country_id" => "1",
          "state_id" => "1",
          "city_id" => "1",
          "neighborhood_id" => "1",
          "street" => @street,
          "number" => "11",
          "zip" => @zip
        },
        "inputKyc" => %{
          "country_id" => "1",
          "phone" => new_kyc.phone,
          "user_type" => new_kyc.user_type,
          "document" => new_kyc.document,
          "document_type" => new_kyc.document_type
        }
      }

      query = """
      mutation ($inputKyc: KycDataUpdateInput!, $inputAddress: AddressUpdateInput!) {
        upsertKyc(input: $inputKyc) {
          document
          document_type
          user_type
        }
        upsertAddress(input: $inputAddress) {
          zip
          street
        }
      }
      """

      res = conn |> post("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "upsertAddress" => updated_address,
          "upsertKyc" => updated_kyc
        }
      } = json_response(res, 200)

      assert updated_address["zip"] == @zip
      assert updated_address["street"] == @street
      assert updated_kyc["document"] == new_kyc.document
      assert updated_kyc["document_type"] == new_kyc.document_type
      assert updated_kyc["user_type"] == new_kyc.user_type
    end

    test "deletes kyc for the given account" do
      kyc = insert(:kyc_data)
      user = kyc.account
      conn = build_conn() |> auth_user(user)

      variables = %{}

      query = """
      mutation {
        deleteKyc {
          status
          reason
        }
      }
      """

      res = conn |> post("/api/graph", query: query, variables: variables)

      response = json_response(res, 200)

      assert response["data"]["deleteKyc"]["status"] == "success"
      assert response["data"]["deleteKyc"]["reason"] == "KYC data deletion succeeded"
    end

    test "deletes address for the given account" do
      address = insert(:address)
      user = address.account

      conn = build_conn() |> auth_user(user)

      variables = %{}

      query = """
      mutation  {
        deleteAddress {
          status
          reason
        }
      }
      """

      res = conn |> post("/api/graph", query: query, variables: variables)

      response = json_response(res, 200)

      assert response["data"]["deleteAddress"]["status"] == "success"
      assert response["data"]["deleteAddress"]["reason"] == "Address data deletion succeeded"
    end
  end
end
