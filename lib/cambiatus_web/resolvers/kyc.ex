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
    params
    |> Kyc.delete_kyc()
    |> case  do
      {:error, reason} ->
        Sentry.capture_message("KYC deletion failed", extra: %{error: reason})
        {:ok, %{status: :error, reason: reason}}

      {:ok, _} ->
        {:ok, %{status: :success, reason: "KYC data deleted successfully"}}
    end
  end

  @spec delete_address(map(), map(), map()) :: {:ok, Address.t()} | {:error, term()}
  def delete_address(_, %{input: params}, _) do
    params
    |> Kyc.delete_address()
    |> case  do
      {:error, reason} ->
        Sentry.capture_message("Address deletion failed", extra: %{error: reason})
        {:ok, %{status: :error, reason: reason}}

      {:ok, _} ->
        {:ok, %{status: :success, reason: "Address data deleted successfully"}}
    end
  end
end
