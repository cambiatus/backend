defmodule Cambiatus.Accounts do
  @moduledoc """
  The Account context.
  """

  import Ecto.Query, warn: false

  alias Cambiatus.Accounts.User
  alias Cambiatus.Commune
  alias Cambiatus.Commune.Transfer
  alias Cambiatus.Repo

  @doc """
  Returns a user when given their `account` string
  """
  @spec get_account_profile(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_account_profile(acct) do
    case Repo.get_by(User, account: acct) do
      nil ->
        {:error, "No user exists with #{acct} as their account"}

      val ->
        {:ok, val}
    end
  end

  @doc "Fetch the list of payers filtered by the given account name"
  @spec filter_payers_by_account(String.t(), String.t()) :: {:ok, list(string)}
  def filter_payers_by_account(recipient, payer) do
    profiles =
      from t in Transfer,
           where: t.to_id == ^recipient and (like(t.from_id, ^("%#{payer}%"))),
           join: u in User,
           on: u.account == t.from_id,
           distinct: true,
           select: u

    {
      :ok,
      profiles
      |> Repo.all()
    }
  end

  @doc "Fetch transfers from various payers to the recipient (may be filtered by the payer or by the date)."
  @spec get_payment_history(map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_payment_history(%{input: %{recipient: recipient, payer: payer, date: date}} = args) do
    {:ok, day_boundary_start, 0} = DateTime.from_iso8601(Date.to_string(date) <> "T00:00:00Z")
    day_boundary_end = DateTime.add(day_boundary_start, 24 * 60 * 60, :seconds)

    Transfer
    |> where(
         [t],
         t.to_id == ^recipient and t.from_id == ^payer and
         (t.created_at >= ^day_boundary_start) and (t.created_at < ^day_boundary_end)
       )
    |> order_by([t], desc: t.created_at)
    |> Commune.get_transfers_from(args)
  end

  @spec get_payment_history(map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_payment_history(%{input: %{recipient: recipient, payer: payer}} = args) do
    Transfer
    |> where([t], t.to_id == ^recipient and t.from_id == ^payer)
    |> order_by([t], desc: t.created_at)
    |> Commune.get_transfers_from(args)
  end

  @spec get_payment_history(map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_payment_history(%{input: %{recipient: recipient, date: date}} = args) do
    {:ok, day_boundary_start, 0} = DateTime.from_iso8601(Date.to_string(date) <> "T00:00:00Z")
    day_boundary_end = DateTime.add(day_boundary_start, 24 * 60 * 60, :seconds)

    Transfer
    |> where(
         [t],
         t.to_id == ^recipient and
         (t.created_at >= ^day_boundary_start) and (t.created_at < ^day_boundary_end)
       )
    |> order_by([t], desc: t.created_at)
    |> Commune.get_transfers_from(args)
  end

  @spec get_payment_history(map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_payment_history(%{input: %{recipient: recipient}} = args) do
    Transfer
    |> where([t], t.to_id == ^recipient)
    |> order_by([t], desc: t.created_at)
    |> Commune.get_transfers_from(args)
  end


  @doc """
  Returns the list of users
  ## Examples

      iex> list_users()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Returns the number of analysis the user already did
  """
  def get_analysis_count(user) do
    query =
      from(c in Cambiatus.Commune.Check,
        where: c.validator_id == ^user.account,
        select: count(c.validator_id)
      )

    case Repo.one(query) do
      nil ->
        {:ok, 0}

      results ->
        {:ok, results}
    end
  end

  @doc """
  Creates a user.
  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.

  ## Examples

  iex> update_user(user, %{field: new_value})
  {:ok, %User{}}

  iex> update_user(user, %{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a User.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

      iex> delete_user(user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

  iex> change_user(user)
  %Ecto.Changeset{source: %User{}}

  """
  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end
end
