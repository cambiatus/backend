defmodule Cambiatus.Auth.SignUp do
  @moduledoc """
  Module responsible for SignUp
  """

  alias Cambiatus.{Accounts, Eos, Kyc, Accounts.User, Auth.Invitation, Auth}
  alias Cambiatus.Kyc.{Address, KycData}

  @contract Application.get_env(:cambiatus, :contract)

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
      {:error, :invalid_user_params, changeset.errors}
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
    if String.match?(public_key, ~r/^(EOS){1}([\w\d]){50}$/) do
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

  def create_eos_account({:error, _} = error), do: error
  def create_eos_account({:error, _, _} = error), do: error

  def create_eos_account(%{account: account, public_key: public_key} = params) do
    case Eos.create_account(public_key, account) do
      {:ok, _} ->
        params

      {:error, :account_already_exists} ->
        {:error, :account_already_exists}

      _ ->
        {:error, :eos_account_creation_failed}
    end
  end

  @doc """
  Creates a new entry on our users table.
  """
  def create_user({:error, _} = error), do: error
  def create_user({:error, _, _} = error), do: error

  def create_user(%{name: name, account: account, email: email} = params) do
    case Accounts.create_user(%{name: name, account: account, email: email}) do
      {:ok, _user} ->
        params

      {:error, _reason} = error ->
        error
    end
  end

  def create_kyc({:error, _} = error), do: error
  def create_kyc({:error, _, _} = error), do: error

  def create_kyc(%{kyc: kyc, address: address, account: account} = params) do
    case Kyc.create(account, kyc, address) do
      {:ok, _} -> params
      _ -> {:error, :failed_to_add_kyc}
    end
  end

  def create_kyc(%{kyc: _, account: _}), do: {:error, :kyc_without_address}
  def create_kyc(%{address: _, account: _}), do: {:error, :address_without_kyc}

  # SignUp without KYC
  def create_kyc(params), do: params

  def invite_user({:error, _} = error), do: error
  def invite_user({:error, _, _} = error), do: error

  def invite_user(%{account: account, invitation_id: id, user_type: user_type} = params) do
    {:ok, invitation} = Auth.find_invitation(id)

    case @contract.netlink(account, invitation.creator_id, invitation.community_id, user_type) do
      {:ok, %{transaction_id: _txid}} ->
        params

      _ ->
        {:error, :netlink_failed}
    end
  end

  def invite_user(%{account: account} = params) do
    case @contract.netlink(account, @contract.cambiatus_account()) do
      {:ok, %{transaction_id: _txid}} ->
        params

      _ ->
        {:error, :netlink_failed}
    end
  end
end
