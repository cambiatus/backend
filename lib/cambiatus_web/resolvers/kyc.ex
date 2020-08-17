defmodule CambiatusWeb.Resolvers.Kyc do
  @moduledoc """
  This module holds the implementation of the resolver for the Kyc context
  use this to resolve any queries and mutations for Kyc and Address
  """

  alias Cambiatus.{Kyc, Kyc.Country, Kyc.State}

  @spec get_country(map(), map(), map()) :: {:ok, Country.t()} | {:error, term()}
  def get_country(_, %{input: params}, _) do
    Kyc.get_country(params.name)
  end

  @spec get_state(map(), map(), map()) :: {:ok, State.t()} | {:error, term()}
  def get_state(_, p, _) do
    Kyc.get_state(1)
  end
end
