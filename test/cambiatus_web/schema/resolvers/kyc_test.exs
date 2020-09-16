defmodule CambiatusWeb.Schema.Resolvers.KycTest do
  @moduledoc """
  Tests for resolvers for the Kyc context.
  """
  use Cambiatus.ApiCase

  describe "Kyc Resolver" do
    @zip "10102"
    @street "Elm Street"

    test "updates kyc data for the given account", %{conn: conn} do
      kyc = insert(:kyc_data)
      user = kyc.account

      new_kyc = build(:kyc_data, %{account: nil})

      variables = %{
        "input" => %{
          "account_id" => user.account,
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

    test "updates address for the given account", %{conn: conn} do
      address = insert(:address)
      user = address.account

      variables = %{
        "input" => %{
          "account_id" => user.account,
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

    test "creates an address and KYC for the given account name", %{conn: conn} do
      usr = insert(:user)
      new_kyc = build(:kyc_data, %{account: nil})

      variables = %{
        "inputAddress" => %{
          "account_id" => usr.account,
          "country_id" => "1",
          "state_id" => "1",
          "city_id" => "1",
          "neighborhood_id" => "1",
          "street" => @street,
          "number" => "11",
          "zip" => @zip
        },
        "inputKyc" => %{
          "account_id" => usr.account,
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

    test "deletes kyc for the given account", %{conn: conn} do
      kyc = insert(:kyc_data)
      user = kyc.account

      variables = %{
        "input" => %{
          "account" => user.account
        }
      }

      query = """
      mutation ($input: KycDeletionInput!) {
        deleteKyc(input: $input) {
          status
          reason
        }
      }
      """

      res = conn |> post("/api/graph", query: query, variables: variables)

      response = json_response(res, 200)

      assert response["data"]["deleteKyc"]["status"] == "SUCCESS"
      assert response["data"]["deleteKyc"]["reason"] == "KYC data deleted successfully"
    end

    test "deletes address for the given account", %{conn: conn} do
      address = insert(:address)
      user = address.account

      variables = %{
        "input" => %{
          "account" => user.account
        }
      }

      query = """
      mutation ($input: KycDeletionInput!) {
        deleteAddress(input: $input) {
          status
          reason
        }
      }
      """

      res = conn |> post("/api/graph", query: query, variables: variables)

      response = json_response(res, 200)

      assert response["data"]["deleteAddress"]["status"] == "SUCCESS"
      assert response["data"]["deleteAddress"]["reason"] == "Address data deleted successfully"
    end
  end
end
