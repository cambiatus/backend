defmodule Cambiatus.Auth.SignUpTest do
  use Cambiatus.DataCase

  alias Cambiatus.Auth.{SignUp, InvitationId}

  describe "Validation functions" do
    test "validate/2 for account" do
      params = %{account: "nonexistingaccounts"}
      assert params == SignUp.validate(params, :account)

      user = insert(:user)
      invalid_params = %{account: user.account}
      assert {:error, :user_already_registred} == SignUp.validate(invalid_params, :account)
    end

    test "validate/2 for changeset" do
      params = %{name: "Test User", account: "testtesttest", email: "a@a.com"}
      assert params == SignUp.validate(params, :changeset)

      account_params = %{name: "Test User", account: "asdf98761234", email: "a@a.com"}

      assert {:error, :invalid_user_params,
              [account: {"has invalid format", [validation: :format]}]} ==
               SignUp.validate(account_params, :changeset)

      email_params = %{name: "Test User", account: "testtesttest", email: "aaa"}

      assert {:error, :invalid_user_params,
              [email: {"has invalid format", [validation: :format]}]} ==
               SignUp.validate(email_params, :changeset)

      required_params = %{name: "Test", account: "", email: "a@a"}

      assert {:error, :invalid_user_params,
              [account: {"can't be blank", [validation: :required]}]} ==
               SignUp.validate(required_params, :changeset)
    end

    test "validate/2 for user_type" do
      params_natural = %{user_type: "natural"}
      params_juridical = %{user_type: "juridical"}
      params_invalid = %{user_type: "somethingelse"}

      assert params_natural == SignUp.validate(params_natural, :user_type)
      assert params_juridical == SignUp.validate(params_juridical, :user_type)
      assert {:error, :invalid_user_type} == SignUp.validate(params_invalid, :user_type)
    end

    test "validate/2 for invitation" do
      invite = insert(:invitation)
      params = %{invitation_id: InvitationId.encode(invite.id)}

      assert params == SignUp.validate(params, :invitation)

      assert {:error, :invalid_invitation_id} ==
               SignUp.validate(%{invitation_id: "-1"}, :invitation)

      assert {:error, :invitation_not_found} ==
               SignUp.validate(%{invitation_id: InvitationId.encode(999_999_999)}, :invitation)
    end

    test "validate/2 for address" do
      address = build(:address)

      address_input = %{
        account_id: nil,
        country_id: address.country_id,
        state_id: address.state_id,
        city_id: address.city_id,
        neighborhood_id: address.neighborhood_id,
        street: address.street,
        number: address.number,
        zip: address.zip
      }

      params = %{address: address_input}
      invalid_address = Map.update!(address_input, :city_id, fn _ -> 999 end)

      assert params == SignUp.validate(params, :address)

      assert {:error, :address_invalid,
              [neighborhood_id: {"is invalid", []}, city_id: {"is invalid", []}]} ==
               SignUp.validate(%{address: invalid_address}, :address)
    end

    test "validate/2 for kyc" do
      kyc = build(:kyc_data)

      kyc_input = %{
        account_id: kyc.account.account,
        country_id: kyc.country.id,
        user_type: kyc.user_type,
        document_type: kyc.document_type,
        document: kyc.document,
        phone: kyc.phone
      }

      params = %{kyc: kyc_input}
      invalid_kyc = Map.update!(kyc_input, :document, &(&1 <> "invalidatedoc"))

      assert params == SignUp.validate(params, :kyc)

      assert {:error, :kyc_invalid,
              [document: {"Document entry is not valid for #{kyc.document_type}", []}]} ==
               SignUp.validate(%{kyc: invalid_kyc}, :kyc)
    end
  end
end
