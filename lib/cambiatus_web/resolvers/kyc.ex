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

  @spec kyc_data_deletion(map(), map(), map()) :: {:ok, KycData.t()} | {:error, term()}
  def kyc_data_deletion(_, %{input: params}, _) do
    Kyc.kyc_data_deletion(params)
  end

end
