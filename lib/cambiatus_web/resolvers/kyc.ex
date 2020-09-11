defmodule CambiatusWeb.Resolvers.Kyc do
  @moduledoc """
  This module holds the implementation of the resolver for the Kyc context
  use this to resolve any queries and mutations for Kyc and Address
  """

  alias Cambiatus.{Kyc, Kyc.KycData, Kyc.Country}

  @spec get_country(map(), map(), map()) :: {:ok, Country.t()} | {:error, term()}
  def get_country(_, %{input: params}, _) do
    Kyc.get_country(params.name)
  end

  @spec update_or_create_kyc(map(), map(), map()) :: {:ok, KycData.t()} | {:error, term()}
  def update_or_create_kyc(_, %{input: params}, _) do
    Kyc.update_or_create_kyc(params)
  end

  @spec update_or_create_address(map(), map(), map()) :: {:ok, Address.t()} | {:error, term()}
  def update_or_create_address(_, %{input: params}, _) do
    Kyc.update_or_create_address(params)
  end
end
