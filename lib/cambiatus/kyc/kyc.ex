defmodule Cambiatus.Kyc do
  @moduledoc """
  Context for all KYC related entities
  """

  alias Cambiatus.{Repo, Accounts.User}
  alias Cambiatus.Kyc.{Country, Address, KycData}
  alias Ecto.Multi

  @spec data :: Dataloader.Ecto.t()
  def data(params \\ %{}), do: Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)

  def query(queryable, _params), do: queryable

  @spec get_country(integer()) :: {:ok, Country.t()} | {:error, term()}
  def get_country(name) do
    case Repo.get_by(Country, name: name) do
      nil ->
        {:error, "country not found or not supported"}

      country ->
        {:ok, country}
    end
  end

  @doc """
  Creates a new KYC for a given account.
  """
  def create(account, kyc) do
    %KycData{}
    |> KycData.changeset(Map.merge(kyc, %{account_id: account}))
    |> Repo.insert()
  end

  def create(account, kyc, address) do
    Multi.new()
    |> Multi.insert(:kyc, KycData.changeset(%KycData{}, Map.merge(kyc, %{account_id: account})))
    |> Multi.insert(
      :address,
      Address.changeset(%Address{}, Map.merge(address, %{account_id: account}))
    )
    |> Repo.transaction()
  end

  @doc """
  Updates the KYC data record for the given user if it already exists
  or inserts a new one if the user hasn't it yet.
  """
  @spec upsert_kyc(User.t(), map()) :: {:ok, KycData.t()} | {:error, binary()}
  def upsert_kyc(%{account: account}, params) do
    kyc_entry =
      case Repo.get_by(KycData, account_id: account) do
        nil -> %KycData{is_verified: false, account_id: account}
        kyc -> kyc
      end

    kyc_entry
    |> KycData.changeset(params)
    |> Repo.insert_or_update()
    |> case do
      {:ok, kyc} -> {:ok, kyc}
      {:error, %{errors: errors_list}} -> {:error, "#{inspect(errors_list)}"}
    end
  end

  @doc """
  Updates the Address of the given user if it already exists
  or inserts new Address if the user hasn't filled it yet.
  """
  @spec upsert_address(map()) :: {:ok, Address.t()} | {:error, binary()}
  def upsert_address(params) do
    address_entry =
      case Repo.get_by(Address, account_id: params.account_id) do
        nil -> %Address{}
        addr -> addr
      end

    address_entry
    |> Address.changeset(params)
    |> Repo.insert_or_update()
    |> case do
      {:ok, address} -> {:ok, address}
      {:error, %{errors: errors_list}} -> {:error, "#{inspect(errors_list)}"}
    end
  end

  @doc """
  Deletes the kyc_data
  """
  def delete_kyc(params) do
    with {:user, %User{}} <- {:user, Repo.get_by(User, account: params.account)},
         {:kyc, %KycData{} = kyc} <-
           {:kyc, Repo.get_by(KycData, account_id: params.account)},
         {:deletion, {:ok, _}} <- {:deletion, Repo.delete(kyc)} do
      {:ok, "KYC data deletion succeeded"}
    else
      {:user, _} -> {:error, "User account doesn't exist"}
      {:kyc, _} -> {:error, "Account does not have KYC data to be deleted."}
      {:deletion, _} -> {:error, "KYC data deletion failed"}
    end
  end

  @doc """
  Deletes the address data
  """
  def delete_address(params) do
    with {:user, %User{}} <- {:user, Repo.get_by(User, account: params.account)},
         {:address, %Address{} = address} <-
           {:address, Repo.get_by(Address, account_id: params.account)},
         {:deletion, {:ok, _}} <- {:deletion, Repo.delete(address)} do
      {:ok, "Address data deletion succeeded"}
    else
      {:user, _} -> {:error, "User account doesn't exist"}
      {:address, _} -> {:error, "Account does not have Address data to be deleted."}
      {:deletion, _} -> {:error, "Address data deletion failed"}
    end
  end
end
