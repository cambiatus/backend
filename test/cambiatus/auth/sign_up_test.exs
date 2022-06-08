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
      {:error, sign_up_account_result} = SignUp.validate(account_params, :changeset)

      assert sign_up_account_result.errors == [
               account: {"has invalid format", [validation: :format]}
             ]

      email_params = %{name: "Test User", account: "testtesttest", email: "aaa"}

      {:error, sign_up_email_result} = SignUp.validate(email_params, :changeset)

      assert sign_up_email_result.errors == [email: {"has invalid format", [validation: :format]}]
      required_params = %{name: "Test", account: "", email: "a@a"}

      {:error, sign_up_required_result} = SignUp.validate(required_params, :changeset)

      assert sign_up_required_result.errors ==
               [account: {"can't be blank", [validation: :required]}]
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
      document_pattern = KycData.get_document_type_pattern(invalid_kyc.document_type)

      changeset =
        %KycData{}
        |> Kernel.struct(invalid_kyc)
        |> Ecto.Changeset.change()
        |> KycData.document_type_error_handler(invalid_kyc.document, document_pattern)

      assert params == SignUp.validate(params, :kyc)

      assert {:error, :kyc_invalid, Map.get(changeset, :errors)} ==
               SignUp.validate(%{kyc: invalid_kyc, account: kyc.account.account}, :kyc)
    end
  end

  describe "Different SignUp routes: " do
    setup do
      creator = insert(:user)

      community =
        :community
        |> insert(%{creator: creator.account})
        |> Repo.preload(:subdomain)

      {:ok, %{community: community}}
    end

    test "sign_up/1 with minimum params", %{community: community} do
      new_user = build(:user)
      _inviter = insert(:user, %{account: "cambiatustes"})
      kyc = build(:kyc_data)

      params = %{
        name: new_user.name,
        account: new_user.account,
        email: new_user.email,
        public_key: "EOS75St6RFmFyXLBnUwheC4H2YTf6tL38saGWiRW1UkdRopERhE7j",
        user_type: kyc.user_type,
        domain: community.subdomain.name
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

      {:error, sign_up_result_1} = SignUp.sign_up(p1)
      assert sign_up_result_1.errors == [name: {"can't be blank", [validation: :required]}]

      p2 = %{name: user.name, account: "accountwith9onit", email: user.email}

      {:error, sign_up_result_2} = SignUp.sign_up(p2)

      assert sign_up_result_2.errors ==
               [account: {"has invalid format", [validation: :format]}]

      p3 = %{name: user.name, account: user.account, email: "invalidemail"}

      {:error, sign_up_result_3} = SignUp.sign_up(p3)

      assert sign_up_result_3.errors ==
               [email: {"has invalid format", [validation: :format]}]

      p4 = %{
        name: user.name,
        account: user.account,
        email: user.email,
        user_type: "invalid"
      }

      assert {:error, :invalid_user_type} == SignUp.sign_up(p4)
    end

    test "sign_up/1 with invitation", %{community: community} do
      invite = insert(:invitation, %{community: community})
      user = build(:user)

      params = %{
        name: user.name,
        email: user.email,
        account: user.account,
        public_key: "EOS75St6RFmFyXLBnUwheC4H2YTf6tL38saGWiRW1UkdRopERhE7j",
        user_type: "natural",
        invitation_id: InvitationId.encode(invite.id),
        domain: community.subdomain.name
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

    test "sign_up/1 with invitation, KYC and address", %{community: community} do
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
        domain: community.subdomain.name,
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

    test "sign_up/1 with KYC", %{community: community} do
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
        },
        domain: community.subdomain.name
      }

      if kyc.user_type == "juridical" do
        assert {:error, :kyc_without_address} = SignUp.sign_up(params)
      else
        assert {:ok, %User{}} = SignUp.sign_up(params)
      end
    end

    test "sign_up/1 with Address", %{community: community} do
      _inviter = insert(:user, %{account: "cambiatustes"})
      user = build(:user)
      address = build(:address)

      params = %{
        name: user.name,
        email: user.email,
        account: user.account,
        public_key: "EOS75St6RFmFyXLBnUwheC4H2YTf6tL38saGWiRW1UkdRopERhE7j",
        user_type: "natural",
        domain: community.subdomain.name,
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
    end
  end
end
