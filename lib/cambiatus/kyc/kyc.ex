defmodule Cambiatus.Kyc do
  @moduledoc """
  Context for all KYC related entities
  """

  alias Cambiatus.{
    Kyc.Country,
    Kyc.KycData,
    Repo
  }

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
  Deletes the kyc_data
  """
  def kyc_data_deletion(params) do
    Repo.get_by(KycData, params.account_id)
    Repo.delete(params)
  end
end
