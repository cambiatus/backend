defmodule CambiatusWeb.Resolvers.Kyc do
  @moduledoc """
  This module holds the implementation of the resolver for the Kyc context
  use this to resolve any queries and mutations for Kyc and Address
  """

  alias Cambiatus.{
    Kyc,
    Kyc.Country,
    Kyc.KycData
  }

  @spec get_country(map(), map(), map()) :: {:ok, Country.t()} | {:error, term()}
  def get_country(_, %{input: params}, _) do
    Kyc.get_country(params.name)
  end

  @spec upsert_kyc(map(), map(), map()) :: {:ok, KycData.t()} | {:error, term()}
  def upsert_kyc(_, %{input: params}, _) do
    Kyc.upsert_kyc(params)
  end

  @spec upsert_address(map(), map(), map()) :: {:ok, Address.t()} | {:error, term()}
  def upsert_address(_, %{input: params}, _) do
    Kyc.upsert_address(params)
  end

  @spec delete_kyc(map(), map(), map()) :: {:ok, KycData.t()} | {:error, term()}
  def delete_kyc(_, %{input: params}, _) do
    Kyc.delete_kyc(params)
  end

  @spec delete_address(map(), map(), map()) :: {:ok, Address.t()} | {:error, term()}
  def delete_address(_, %{input: params}, _) do
    Kyc.delete_address(params)
  end
end
