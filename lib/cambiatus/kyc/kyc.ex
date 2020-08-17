defmodule Cambiatus.Kyc do
  @moduledoc """
  Context for all KYC related entities
  """
  alias Cambiatus.{Kyc.Country, Repo, Kyc.State}

  @spec get_country(integer()) :: {:ok, Country.t()} | {:error, term()}
  def get_country(name) do
    case Repo.get_by(Country, name: name) do
      nil ->
        {:error, "country not found or not supported"}

      country ->
        {:ok, country}
    end
  end

  @spec get_state(integer()) :: {:ok, State.t()} | {:error, term()}
  def get_state(id) do
    case(Repo.get(State, id)) do
      nil ->
        {:error, "No state found"}

      state ->
        {:ok, state}
    end
  end
end
