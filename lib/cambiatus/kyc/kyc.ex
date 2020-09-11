defmodule Cambiatus.Kyc do
  @moduledoc """
  Context for all KYC related entities
  """

  alias Cambiatus.{Kyc.Country, Kyc.Address, Kyc.KycData, Repo}

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
  Updates the KYC data record for the given user if it already exists
  or creates a new KYC data record if user hasn't it yet.
  """
  @spec update_or_create_kyc(map()) :: {:ok, KycData.t()} | {:error, binary()}
  def update_or_create_kyc(params) do
    kyc_entry =
      case Repo.get_by(KycData, account_id: params.account_id) do
        nil -> %KycData{is_verified: false}
        kyc -> kyc
      end

    result =
      kyc_entry
      |> KycData.changeset(params)
      |> Repo.insert_or_update()

    case result do
      {:ok, kyc} -> {:ok, kyc}
      {:error, %{errors: errors_list}} -> {:error, "#{inspect(errors_list)}"}
    end
  end

  @spec update_or_create_address(map()) :: {:ok, Address.t()} | {:error, binary()}
  def update_or_create_address(params) do
    address_entry =
      case Repo.get_by(Address, account_id: params.account_id) do
        nil -> %Address{}
        addr -> addr
      end

    result =
      address_entry
      |> Address.changeset(params)
      |> Repo.insert_or_update()

    case result do
      {:ok, address} -> {:ok, address}
      {:error, %{errors: errors_list}} -> {:error, "#{inspect(errors_list)}"}
    end
  end
end
