defmodule Cambiatus.Auth.SignUp do
  @moduledoc """
  Module responsible for SignUp
  """

  alias Cambiatus.{Accounts, Kyc, Accounts.User, Auth.Invitation, Auth}
  alias Cambiatus.Kyc.{Address, KycData}

  @contract Application.compile_env(:cambiatus, :contract)

  @doc """
  Signs up a new user.

  New users may or may not have been invited. Also, the user can provide KYC information and Address during the sign_up process.

  ## Steps
  - Validate all params: account, kyc data, invitation, and address
  - Create EOS Account
  - Invite to the proper community (Default community or the one in the invitation)
  """
  def sign_up(params) do
    params
    |> set_sentry()
    |> validate_all()
    |> create_eos_account()
    |> create_user()
    |> create_kyc()
    |> invite_user()
    |> case do
      {:error, _} = error ->
        error

      {:error, _, _} = error ->
        error

      _result ->
        {:ok, Accounts.get_user(params.account)}
    end
  end

  @doc """
  Adds context so we can better understand fails and errors on production
  """
  def set_sentry(params) do
    Sentry.Context.set_extra_context(params)

    params
  end

  @doc """
  Validates the given params. Depending on the structure do different validations
  """
  def validate_all(params) do
    params
    |> validate(:account)
    |> validate(:changeset)
    |> validate(:user_type)
    |> validate(:public_key)
    |> validate(:invitation)
    |> validate(:address)
    |> validate(:kyc)
    |> validate(:community)
  end

  def validate({:error, _} = error, _), do: error
  def validate({:error, _, _} = error, _), do: error

  @spec validate(
          map(),
          :account | :changeset | :invitation | :user_type | :public_key | :address | :kyc
        ) ::
          map() | {:error, any()}
  def validate(%{account: account} = params, :account) do
    case Accounts.get_user(account) do
      nil ->
        params

      %User{} ->
        {:error, :user_already_registred}
    end
  end

  def validate(%{name: name, account: account, email: email} = params, :changeset) do
    changeset = Accounts.change_user(%{name: name, account: account, email: email})

    if changeset.valid? do
      params
    else
      {:error, changeset}
    end
  end

  def validate(%{user_type: user_type} = params, :user_type) do
    if user_type in ["natural", "juridical"] do
      params
    else
      {:error, :invalid_user_type}
    end
  end

  def validate(%{public_key: public_key} = params, :public_key) do
    if String.match?(public_key, ~r/^(EOS){1}([\w\d]){50,53}$/) do
      params
    else
      {:error, :invalid_public_key}
    end
  end

  def validate(%{invitation_id: id} = params, :invitation) do
    case Auth.find_invitation(id) do
      {:ok, %Invitation{}} ->
        params

      {:error, :invitation_not_found} = error ->
        error

      {:error, :decode_failed} ->
        {:error, :invalid_invitation_id}
    end
  end

  def validate(params, :invitation), do: params

  def validate(%{address: address} = params, :address) do
    changeset = Address.changeset(%Address{}, address)

    if changeset.valid? do
      params
    else
      {:error, :address_invalid, changeset.errors}
    end
  end

  def validate(params, :address), do: params

  def validate(%{kyc: kyc} = params, :kyc) do
    changeset = KycData.changeset(%KycData{}, Map.merge(kyc, %{account_id: params.account}))

    if changeset.valid? do
      params
    else
      {:error, :kyc_invalid, changeset.errors}
    end
  end

  def validate(params, :kyc), do: params

  def validate(%{community: _community} = params, :community), do: params

  def create_eos_account({:error, _} = error), do: error
  def create_eos_account({:error, _, _} = error), do: error

  def create_eos_account(%{account: account, public_key: public_key} = params) do
    case @contract.create_account(public_key, account) do
      {:ok, _} ->
        params

      {:error, :account_already_exists} ->
        {:error, :account_already_exists}

      other_error ->
        Sentry.capture_message("Error creating account on EOS", extra: other_error)
        {:error, :eos_account_creation_failed}
    end
  end

  @doc """
  Creates a new entry on our users table.
  """
  def create_user({:error, _} = error), do: error
  def create_user({:error, _, _} = error), do: error

  def create_user(%{name: _, account: _, email: _} = params) do
    new_user = Map.merge(params, %{created_at: DateTime.utc_now()})

    case Accounts.create_user(new_user) do
      {:ok, _user} ->
        params

      {:error, _reason} = error ->
        error
    end
  end

  def create_kyc({:error, _} = error), do: error
  def create_kyc({:error, _, _} = error), do: error

  def create_kyc(%{kyc: kyc, address: address, account: account, user_type: "juridical"} = params) do
    case Kyc.create(account, kyc, address) do
      {:ok, _} -> params
      _ -> {:error, :failed_to_add_kyc}
    end
  end

  def create_kyc(%{kyc: _, account: _, user_type: "juridical"}),
    do: {:error, :kyc_without_address}

  def create_kyc(%{address: _, account: _, user_type: "juridical"}),
    do: {:error, :address_without_kyc}

  def create_kyc(%{kyc: kyc, account: account, user_type: "natural"} = params) do
    case Kyc.create(account, kyc) do
      {:ok, _} -> params
      _ -> {:error, :failed_to_add_kyc}
    end
  end

  def create_kyc(%{kyc: _, address: _, account: _, user_type: "natural"}),
    do: {:error, :natural_user_type_with_address}

  def create_kyc(%{kyc: kyc, address: address, account: account} = params) do
    case Kyc.create(account, kyc, address) do
      {:ok, _} -> params
      _ -> {:error, :failed_to_add_kyc}
    end
  end

  # SignUp without KYC
  def create_kyc(params), do: params

  def invite_user({:error, _} = error), do: error
  def invite_user({:error, _, _} = error), do: error

  def invite_user(%{account: account, invitation_id: id, user_type: user_type} = params) do
    {:ok, invitation} = Auth.find_invitation(id)

    case @contract.netlink(account, invitation.creator_id, invitation.community_id, user_type) do
      {:ok, %{transaction_id: _txid}} ->
        params

      {:error, details} ->
        Sentry.capture_message("Error during netlink", extra: details)
        {:error, :netlink_failed}

      _ ->
        {:error, :netlink_failed}
    end
  end

  def invite_user(%{account: account, community: community} = params) do
    with {true, _} <- {community.auto_invite, community},
         {:ok, %{transaction_id: _txid}} <-
           @contract.netlink(account, community.creator, community.symbol, "natural") do
      params
    else
      {false, community} ->
        {:error,
         "Sorry we can't add you to this community: #{community.symbol}, as it don't allow for auto invites, please provide an invitation"}

      _ ->
        {:error, "Sorry we can't sign you up"}
    end
  end
end
