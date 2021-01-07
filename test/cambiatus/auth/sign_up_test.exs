defmodule Cambiatus.Auth.SignUpTest do
  use Cambiatus.DataCase

  alias Cambiatus.Auth.{SignUp, InvitationId}

  alias Cambiatus.{
    Accounts.User,
    Kyc.KycData
  }

  describe "Validation functions: " do
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
        country_id: kyc.country.id,
        user_type: kyc.user_type,
        document_type: kyc.document_type,
        document: kyc.document,
        phone: kyc.phone
      }

      params = %{kyc: kyc_input, account: kyc.account.account}
      invalid_kyc = Map.update!(kyc_input, :document, &(&1 <> "invalidatedoc"))

      assert params == SignUp.validate(params, :kyc)

      assert {:error, :kyc_invalid,
              [document: {"Document entry is not valid for #{kyc.document_type}", []}]} ==
               SignUp.validate(%{kyc: invalid_kyc, account: kyc.account.account}, :kyc)
    end
  end

  describe "Different SignUp routes: " do
    setup do
      insert(:community, %{symbol: "BES"})

      :ok
    end

    test "sign_up/1 with minimum params" do
      new_user = build(:user)
      _inviter = insert(:user, %{account: "cambiatustes"})
      kyc = build(:kyc_data)

      params = %{
        name: new_user.name,
        account: new_user.account,
        email: new_user.email,
        public_key: "EOS75St6RFmFyXLBnUwheC4H2YTf6tL38saGWiRW1UkdRopERhE7j",
        user_type: kyc.user_type
      }

      assert {:ok, %User{}} = SignUp.sign_up(params)
    end

    test "sign_up/1 with already registered account" do
      user = insert(:user)

      params = %{
        name: "Another Name",
        account: user.account,
        email: "a@a.com",
        public_key: "",
        user_type: ""
      }

      assert {:error, :user_already_registred} = SignUp.sign_up(params)
    end

    test "sign_up/1 with invalid user data" do
      user = build(:user)
      p1 = %{name: "", account: user.account, email: user.email}

      assert {:error, :invalid_user_params, [name: {"can't be blank", [validation: :required]}]} =
               SignUp.sign_up(p1)

      p2 = %{name: user.name, account: "accountwith9onit", email: user.email}

      assert {:error, :invalid_user_params,
              [account: {"has invalid format", [validation: :format]}]} = SignUp.sign_up(p2)

      p3 = %{name: user.name, account: user.account, email: "invalidemail"}

      assert {:error, :invalid_user_params,
              [email: {"has invalid format", [validation: :format]}]} == SignUp.sign_up(p3)

      p4 = %{name: user.name, account: user.account, email: user.email, user_type: "invalid"}

      assert {:error, :invalid_user_type} == SignUp.sign_up(p4)
    end

    test "sign_up/1 with invitation" do
      community = insert(:community)
      invite = insert(:invitation, %{community: community})
      user = build(:user)

      params = %{
        name: user.name,
        email: user.email,
        account: user.account,
        public_key: "EOS75St6RFmFyXLBnUwheC4H2YTf6tL38saGWiRW1UkdRopERhE7j",
        user_type: "natural",
        invitation_id: InvitationId.encode(invite.id)
      }

      assert {:ok, %User{}} = SignUp.sign_up(params)
    end

    test "sign_up/1 with invalid invitation" do
      user = build(:user)

      params = %{
        name: user.name,
        email: user.email,
        account: user.account,
        public_key: "EOS75St6RFmFyXLBnUwheC4H2YTf6tL38saGWiRW1UkdRopERhE7j",
        user_type: "natural",
        invitation_id: "somethinginvalid"
      }

      assert {:error, :invalid_invitation_id} = SignUp.sign_up(params)
    end

    test "sign_up/1 with non-existing invitation" do
      user = build(:user)

      params = %{
        name: user.name,
        email: user.email,
        account: user.account,
        public_key: "EOS75St6RFmFyXLBnUwheC4H2YTf6tL38saGWiRW1UkdRopERhE7j",
        user_type: "natural",
        invitation_id: InvitationId.encode(0)
      }

      assert {:error, :invitation_not_found} = SignUp.sign_up(params)
    end

    test "sign_up/1 with invitation, KYC and address" do
      community = insert(:community)
      invite = insert(:invitation, %{community: community})
      user = build(:user)
      kyc = build(:kyc_data)
      address = build(:address)

      params = %{
        name: user.name,
        email: user.email,
        account: user.account,
        public_key: "EOS75St6RFmFyXLBnUwheC4H2YTf6tL38saGWiRW1UkdRopERhE7j",
        user_type: kyc.user_type,
        invitation_id: InvitationId.encode(invite.id),
        kyc: %{
          user_type: kyc.user_type,
          document: kyc.document,
          document_type: kyc.document_type,
          phone: kyc.phone,
          country_id: kyc.country.id
        },
        address: %{
          account_id: address.account.account,
          street: address.street,
          neighborhood_id: address.neighborhood_id,
          city_id: address.city_id,
          state_id: address.state_id,
          country_id: address.country_id,
          zip: address.zip,
          number: address.number
        }
      }

      assert {:ok, %User{}} = SignUp.sign_up(params)

      found_kyc = Repo.get_by!(KycData, %{account_id: user.account})
      assert found_kyc.account_id == user.account
    end

    test "sign_up/1 with KYC" do
      _community = insert(:community)
      _inviter = insert(:user, %{account: "cambiatustes"})
      user = build(:user)
      kyc = build(:kyc_data)

      params = %{
        name: user.name,
        email: user.email,
        account: user.account,
        public_key: "EOS75St6RFmFyXLBnUwheC4H2YTf6tL38saGWiRW1UkdRopERhE7j",
        user_type: kyc.user_type,
        kyc: %{
          user_type: kyc.user_type,
          document: kyc.document,
          document_type: kyc.document_type,
          phone: kyc.phone,
          country_id: kyc.country.id
        }
      }

      assert {:ok, %User{}} = SignUp.sign_up(params)
    end

    test "sign_up/1 with Address" do
      _community = insert(:community)
      user = build(:user)
      address = build(:address)

      params = %{
        name: user.name,
        email: user.email,
        account: user.account,
        public_key: "EOS75St6RFmFyXLBnUwheC4H2YTf6tL38saGWiRW1UkdRopERhE7j",
        user_type: "natural",
        address: %{
          account_id: address.account.account,
          street: address.street,
          neighborhood_id: address.neighborhood_id,
          city_id: address.city_id,
          state_id: address.state_id,
          country_id: address.country_id,
          zip: address.zip,
          number: address.number
        }
      }

      assert {:error, :address_without_kyc} = SignUp.sign_up(params)
    end
  end
end
