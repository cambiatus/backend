defmodule Cambiatus.Accounts do
  @moduledoc """
  The Account context.
  """

  import Ecto.Query

  alias Cambiatus.Repo
  alias Cambiatus.Accounts.User
  alias Cambiatus.Auth
  alias Cambiatus.Auth.Request
  alias Cambiatus.Commune.{Community, Network, Transfer}
  alias Cambiatus.Objectives.Check

  @contract Application.compile_env(:cambiatus, :contract)

  @spec data :: Dataloader.Ecto.t()
  def data(params \\ %{}) do
    Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)
  end

  def query(User, %{query: query}) do
    User.search(User, query)
  end

  def query(queryable, _params), do: queryable

  def search_in_community(%Community{} = community, filters \\ %{}) do
    search =
      User
      |> join(:inner, [u], c in assoc(u, :communities))
      |> where([u, c], c.symbol == ^community.symbol)
      |> User.search(filters)
      |> Repo.all()

    {:ok, search}
  end

  def verify_pass(account, password) do
    with %Request{phrase: phrase} <- Auth.get_valid_request(account),
         {:ok, public_key} <- @contract.get_public_key(account),
         {:ok, true} <- @contract.verify_sign(password, phrase, public_key) do
      true
    else
      _ -> false
    end
  end

  @doc """
  Returns a user when given their `account` string
  """
  @spec get_account_profile(String.t()) :: {:ok, map()} | {:error, String.t()}
  def get_account_profile(account) do
    case Repo.get_by(User, account: account) do
      nil ->
        {:error, "No user exists with #{account} as their account"}

      user ->
        {:ok, user}
    end
  end

  @doc """
  Returns a list of payers (users, who made transfers to the given user) whose account includes the string,
  given as the second argument (e.g. `bes` <- `bespiral`).
  """
  @spec get_payers_by_account(map(), map()) :: {:ok, list(User.t())}
  def get_payers_by_account(%User{} = user, %{account: _} = payer) do
    profiles =
      from(t in Transfer,
        where: t.to_id == ^user.account and like(t.from_id, ^"#{payer.account}%"),
        join: u in User,
        on: u.account == t.from_id,
        distinct: true,
        select: u
      )

    {:ok, Repo.all(profiles)}
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

  def get_user(id) do
    case Repo.get(User, id) do
      nil ->
        {:error, "No user with account: #{id} found"}

      val ->
        {:ok, val}
    end
  end

  @doc """
  Returns the number of analysis the user already did
  """
  def get_analysis_count(user) do
    query =
      from(c in Check,
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

  def get_contribution_count(user, community_id \\ nil) do
    query =
      from(c in Cambiatus.Payments.Contribution,
        where: c.user_id == ^user.account,
        where: c.status == :approved,
        select: count(c.id)
      )

    query =
      if is_nil(community_id) do
        query
      else
        where(query, [c], c.community_id == ^community_id)
      end

    case Repo.one(query) do
      nil ->
        {:ok, 0}

      count ->
        {:ok, count}
    end
  end

  def get_member_since(user, community) do
    Network
    |> Network.by_community(community.symbol)
    |> Network.by_user(user.account)
    |> select([n], n.created_at)
    |> Repo.one()
    |> case do
      nil ->
        {:error, "Could not find user in community"}

      member_since ->
        {:ok, member_since}
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
  def change_user(params) do
    User.changeset(%User{}, params)
  end
end
