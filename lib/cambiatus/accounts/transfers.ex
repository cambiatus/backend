defmodule Cambiatus.Accounts.Transfers do
  @moduledoc """
  Fetching and filtering transfers in the context of the user.
  """

  import Ecto.Query, warn: false

  alias Cambiatus.Accounts.User
  alias Cambiatus.Commune
  alias Cambiatus.Commune.Transfer

  @doc """
  Incoming transfers to the user from the given account on the given date.
  """
  @spec get_transfers(map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(
        %User{} = user,
        %{direction: :incoming, second_party_account: second_party_account, date: date} = args
      ) do
    user
    |> query_incoming_transfers
    |> where([t], t.from_id == ^second_party_account)
    |> query_transfers_by_date(date)
    |> Commune.get_transfers_from(args)
  end

  @doc """
  Incoming transfers to the user from the given account.
  """
  @spec get_transfers(map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(
        %User{} = user,
        %{direction: :incoming, second_party_account: second_party_account} = args
      ) do
    user
    |> query_incoming_transfers
    |> where([t], t.from_id == ^second_party_account)
    |> Commune.get_transfers_from(args)
  end

  @doc """
  Incoming transfers to the user on the given date.
  """
  @spec get_transfers(map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%User{} = user, %{direction: :incoming, date: date} = args) do
    user
    |> query_incoming_transfers
    |> query_transfers_by_date(date)
    |> Commune.get_transfers_from(args)
  end

  @doc """
  All incoming transfers to the user.
  """
  @spec get_transfers(map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%User{} = user, %{direction: :incoming} = args) do
    user
    |> query_incoming_transfers
    |> Commune.get_transfers_from(args)
  end

  @doc """
  Outgoing transfers from the user to the given account on the given date.
  """
  @spec get_transfers(map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(
        %User{} = user,
        %{direction: :outgoing, second_party_account: second_party_account, date: date} = args
      ) do
    user
    |> query_outgoing_transfers
    |> where([t], t.to_id == ^second_party_account)
    |> query_transfers_by_date(date)
    |> Commune.get_transfers_from(args)
  end

  @doc """
  Outgoing transfers from the user to the given account.
  """
  @spec get_transfers(map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(
        %User{} = user,
        %{direction: :outgoing, second_party_account: second_party_account} = args
      ) do
    user
    |> query_outgoing_transfers
    |> where([t], t.to_id == ^second_party_account)
    |> Commune.get_transfers_from(args)
  end

  @doc """
  Outgoing transfers from the user on the given date.
  """
  @spec get_transfers(map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%User{} = user, %{direction: :outgoing, date: date} = args) do
    user
    |> query_outgoing_transfers
    |> query_transfers_by_date(date)
    |> Commune.get_transfers_from(args)
  end

  @doc """
  All outgoing transfers from the user.
  """
  @spec get_transfers(map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%User{} = user, %{direction: :outgoing} = args) do
    user
    |> query_outgoing_transfers
    |> Commune.get_transfers_from(args)
  end

  @doc """
  All transfers (incoming and outgoing) for the given date.
  """
  @spec get_transfers(map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%User{} = user, %{date: date} = args) do
    user
    |> query_all_transfers
    |> query_transfers_by_date(date)
    |> Commune.get_transfers_from(args)
  end

  @doc """
  All transfers (incoming and outgoing) belonging to the user where the given account is involved as a second party.
  """
  @spec get_transfers(map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%User{} = user, %{second_party_account: second_party_account} = args) do
    Transfer
    |> where(
      [t],
      (t.from_id == ^user.account and t.to_id == ^second_party_account) or
        (t.from_id == ^second_party_account and t.to_id == ^user.account)
    )
    |> Commune.get_transfers_from(args)
  end

  @doc """
  All transfers (incoming and outgoing) belonging to the user.
  """
  @spec get_transfers(map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%User{} = user, args) do
    user
    |> query_all_transfers
    |> Commune.get_transfers_from(args)
  end

  @spec query_all_transfers(map()) :: Ecto.Queryable.t()
  def query_all_transfers(%User{account: account}) do
    Transfer
    |> where([t], t.from_id == ^account or t.to_id == ^account)
  end

  @spec query_incoming_transfers(map()) :: Ecto.Queryable.t()
  def query_incoming_transfers(%User{account: account}) do
    Transfer
    |> where([t], t.to_id == ^account)
  end

  @spec query_outgoing_transfers(map()) :: Ecto.Queryable.t()
  def query_outgoing_transfers(%User{account: account}) do
    Transfer
    |> where([t], t.from_id == ^account)
  end

  @spec query_transfers_by_date(Ecto.Queryable.t(), String.t()) :: Ecto.Queryable.t()
  def query_transfers_by_date(query, date) do
    to_datetime = fn d ->
      {:ok, datetime, _} =
        (Date.to_iso8601(d) <> "T00:00:00Z")
        |> DateTime.from_iso8601()

      datetime
    end

    day_boundary_start = to_datetime.(date)
    day_boundary_end = to_datetime.(Date.add(date, 1))

    query
    |> where(
      [t],
      t.created_at >= ^day_boundary_start and t.created_at < ^day_boundary_end
    )
  end
end
