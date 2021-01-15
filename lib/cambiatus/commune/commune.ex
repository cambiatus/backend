defmodule Cambiatus.Commune do
  @moduledoc """
  The Commune context. Handles everything related to communities. Network, Transfers, Details, Indexes, etc
  """

  import Ecto.Query

  alias Absinthe.Relay.Connection

  alias Cambiatus.{
    Accounts.User,
    Commune.Action,
    Commune.Check,
    Commune.Community,
    Commune.Claim,
    Commune.Network,
    Commune.Objective,
    Commune.Transfer,
    Commune.Validator,
    Repo
  }

  @spec data :: Dataloader.Ecto.t()
  def data(params \\ %{}), do: Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)

  def query(Objective, _) do
    Objective
    |> order_by([c], desc: c.created_at)
  end

  def query(Action, %{input: filters}) do
    query =
      filters
      |> Enum.reduce(Action, fn
        {:creator, account}, query ->
          query
          |> Action.created_by(account)

        {:validator, account}, query ->
          query
          |> Action.with_validator(account)

        {:is_completed, is_completed}, query ->
          query
          |> Action.completed(is_completed)

        {:verification_type, verification_type}, query ->
          query
          |> Action.with_verification_type_of(verification_type)

        _, query ->
          query
      end)
      |> Action.ordered()

    query
  end

  def query(Check, %{input: filters}) do
    query =
      filters
      |> Enum.reduce(Check, fn
        {:validator, account}, query ->
          query
          |> where([c], c.validator_id == ^account)

        _, query ->
          query
      end)
      |> order_by([c], c.created_at)

    query
  end

  def query(Claim, %{community_id: community_id}) do
    Claim
    |> Claim.by_community(community_id)
  end

  def query(queryable, _params) do
    queryable
  end

  @doc """
  Fetch a transfer

  ## Parameters
  * id: id of the tranfer to be fetched
  """
  @spec get_transfer(integer()) :: {:ok, Transfer.t()} | {:error, term}
  def get_transfer(id) do
    case Repo.get(Transfer, id) do
      nil ->
        {:error, "No tranfer with the id: #{id} found"}

      val ->
        {:ok, val}
    end
  end

  @doc """
  Fetch an action

  ## Parameters
  * id: the id of the action being sought
  """
  @spec get_action(integer()) :: {:ok, Action.t()} | {:error, term}
  def get_action(id) do
    case Repo.get(Action, id) do
      nil ->
        {:error, "Action with id: #{id} not found"}

      val ->
        {:ok, val}
    end
  end

  @doc """
  Fetch a single claim by id

  ## Parameters
  * id: the id of the claim to be fetched
  """
  @spec get_claim(integer()) :: {:ok, Claim.t()} | {:error, term}
  def get_claim(id) do
    case Repo.get(Claim, id) do
      nil ->
        {:error, "No claim with id: #{id} found"}

      val ->
        {:ok, val}
    end
  end

  @doc """
  Fetch a claimer's claimed action

  ## Parameters
  * claimer: the claimer's account name
  """
  @spec get_actor_claims(String.t()) :: {:ok, list(Claim.t())} | {:error, term}
  def get_actor_claims(claimer) do
    query =
      from(c in Claim,
        where: c.claimer_id == ^claimer,
        order_by: fragment("? DESC", c.created_at)
      )

    validations = Repo.all(query)

    {:ok, validations}
  end

  @doc """
  Fetch all claims from a community

  ### Parameters
  * symbol: the community's symbol
  """
  @spec get_community_claims(String.t()) :: {:ok, list(Claim.t())} | {:error, term}
  def get_community_claims(symbol) do
    query =
      from(o in Objective,
        where: o.community_id == ^symbol,
        # pick this objectives actions
        join: a in Action,
        on: a.objective_id == o.id,
        # pick the actions claims
        join: c in Claim,
        on: c.action_id == a.id,
        order_by: fragment("? DESC", c.created_at),
        select: c
      )

    community_claims = Repo.all(query)

    {:ok, community_claims}
  end

  @doc """
  Fetch pending claims that the specified `account` is an analyser.
  That is, claims that have their status as `pending` and the `account` haven't voted on it yet.

  ## Params
  * community_id: String with the community symbol
  * account: String. User account
  """
  @spec claim_analysis_query(term, term) :: Ecto.Query.t()
  def claim_analysis_query(community_id, account) do
    Claim
    |> join(:left, [c], a in assoc(c, :action))
    |> join(:left, [c, a], o in assoc(a, :objective))
    |> join(:left, [c, a], v in Validator, on: v.action_id == c.action_id)
    |> where(
      [c, a, o, v],
      o.community_id == ^community_id and v.validator_id == ^account and a.is_completed == false and
        c.status == "pending" and
        fragment(
          "select count(*) from checks b where b.claim_id = ?.id and b.validator_id = ?",
          c,
          ^account
        ) == 0
    )
    |> order_by([c], desc: c.id)
  end

  @doc """
  Fetch all claims that the specified `account` is an analyser.
  It includes the claims that the user still have to give a vote

  ## Params
  * community_id: String with the community symbol
  * account: String. User account
  """
  @spec claim_analysis_history_query(term, term) :: Ecto.Query.t()
  def claim_analysis_history_query(community_id, account) do
    from(c in Claim,
      join: a in Action,
      on: a.id == c.action_id,
      join: o in Objective,
      on: o.id == a.objective_id,
      join: v in Validator,
      on: v.action_id == c.action_id,
      where: o.community_id == ^community_id,
      where: v.validator_id == ^account,
      order_by: [desc: c.created_at]
    )
  end

  def claim_filter_status(query, status) do
    query |> where(status: ^status)
  end

  def claim_filter_claimer(query, claimer) do
    query |> where(claimer_id: ^claimer)
  end

  @doc """
  Provided with a profile this collects all transfers belong to the user
  """
  def get_transfers(%User{account: account}, pagination_args) do
    Transfer
    |> where([t], t.from_id == ^account or t.to_id == ^account)
    |> get_transfers_from(pagination_args)
  end

  @doc """
  Given a community this collects all transfers belonging to the community
  """
  @spec get_transfers(map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%Community{symbol: symbol}, pagination_args) do
    Transfer
    |> where([t], t.community_id == ^symbol)
    |> get_transfers_from(pagination_args)
  end

  @spec get_transfers_from(Ecto.Queryable.t(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers_from(query, pagination_args) do
    query
    |> order_by([t], desc: t.created_at)
    |> select([t], t)
    |> Connection.from_query(&Repo.all/1, pagination_args)
  end

  @doc """
  Returns the list of communities.

  ## Examples

      iex> list_communities()
      {:ok, [%Community{}, ...]}

  """
  @spec list_communities() :: {:ok, list(map())}
  def list_communities do
    with results <- Repo.all(Community) do
      {:ok, results}
    end
  end

  @doc """
  Gets a single community.

  Returns `{:error, reason}` if the community doesn't exist.

  ## Examples

    iex> get_community(123)
    %Community{}

    iex> get_community(456)
    {:error, "No community exists with the symbol: 456"}

  """
  @spec get_community(String.t()) :: {:ok, term()} | {:error, term()}
  def get_community(sym) do
    with nil <- Repo.get_by(Community, symbol: sym) do
      {:error, "No community exists with the symbol: #{sym}"}
    else
      val ->
        {:ok, val}
    end
  end

  @doc """
  Gets a single community.

  Raises `Ecto.NoResultsError` if the Community does not exist.

  ## Examples

      iex> get_community!(123)
      %Community{}

      iex> get_community!(456)
      ** (Ecto.NoResultsError)

  """
  def get_community!(id), do: Repo.get!(Community, id)

  @doc """
  Creates a community.

  ## Examples

      iex> create_community(%{field: value})
      {:ok, %Community{}}

      iex> create_community(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_community(attrs \\ %{}) do
    %Community{}
    |> Community.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a community.

  ## Examples

      iex> update_community(community, %{field: new_value})
      {:ok, %Community{}}

      iex> update_community(community, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_community(%Community{} = community, attrs) do
    community
    |> Community.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Community.

  ## Examples

      iex> delete_community(community)
      {:ok, %Community{}}

      iex> delete_community(community)
      {:error, %Ecto.Changeset{}}

  """
  def delete_community(%Community{} = community) do
    Repo.delete(community)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking community changes.

  ## Examples

      iex> change_community(community)
      %Ecto.Changeset{source: %Community{}}

  """
  def change_community(%Community{} = community) do
    Community.changeset(community, %{})
  end

  @doc """
  Returns the list of network.

  ## Examples

      iex> list_network()
      [%Network{}, ...]

  """
  def list_network do
    Repo.all(Network)
  end

  def list_community_network(community_id) do
    Repo.all(from(n in Network, where: n.community_id == ^community_id))
  end

  def community_validators(community_id) do
    query =
      from(u in User,
        join: v in Validator,
        on: v.validator_id == u.account,
        join: a in Action,
        on: a.id == v.action_id,
        join: o in Objective,
        on: a.objective_id == o.id,
        where: o.community_id == ^community_id,
        distinct: v.validator_id
      )

    Repo.all(query)
  end

  @doc """
  Gets a single network.

  Raises `Ecto.NoResultsError` if the Network does not exist.

  ## Examples

      iex> get_network!(123)
      %Network{}

      iex> get_network!(456)
      ** (Ecto.NoResultsError)

  """
  def get_network!(id), do: Repo.get!(Network, id)

  @doc """
  Creates a network.

  ## Examples

      iex> create_network(%{field: value})
      {:ok, %Network{}}

      iex> create_network(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_network(attrs \\ %{}) do
    %Network{}
    |> Network.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking network changes.

  ## Examples

      iex> change_network(network)
      %Ecto.Changeset{source: %Network{}}

  """
  def change_network(%Network{} = network) do
    Network.changeset(network, %{})
  end

  @doc """
  Returns how many transfers a user has done
  """
  def get_transfers_count(%User{account: account}) do
    query =
      from(t in Cambiatus.Commune.Transfer,
        where: t.from_id == ^account or t.to_id == ^account,
        select: count(t.id)
      )

    case Repo.one(query) do
      nil ->
        {:ok, 0}

      results ->
        {:ok, results}
    end
  end

  @doc """
  Returns how many transfers has happened on a community
  """
  def get_transfers_count(%Community{symbol: id}) do
    query =
      from(t in Cambiatus.Commune.Transfer,
        where: t.community_id == ^id,
        select: count(t.id)
      )

    case Repo.one(query) do
      nil ->
        {:ok, 0}

      results ->
        {:ok, results}
    end
  end

  def get_members_count(%Community{symbol: id}) do
    query =
      from(n in Cambiatus.Commune.Network,
        where: n.community_id == ^id,
        select: count(n.id)
      )

    case Repo.one(query) do
      nil ->
        {:ok, 0}

      results ->
        {:ok, results}
    end
  end

  def get_members_count(symbol) when is_binary(symbol) do
    get_members_count(%Community{symbol: symbol})
  end

  def get_transfer_count(%Community{symbol: id}) do
    query =
      from(t in Cambiatus.Commune.Transfer,
        where: t.community_id == ^id,
        select: count(t.id)
      )

    query
    |> Repo.one()
    |> case do
      nil ->
        {:ok, 0}

      results ->
        {:ok, results}
    end
  end

  def get_action_count(%Community{symbol: id}) do
    query =
      from(a in Action,
        join: o in Objective,
        on: a.objective_id == o.id,
        where: o.community_id == ^id,
        select: count(a.id)
      )

    query
    |> Repo.one()
    |> case do
      nil -> {:ok, 0}
      results -> {:ok, results}
    end
  end

  def get_claim_count(%Community{symbol: id}) do
    query =
      from(c in Claim,
        join: a in Action,
        join: o in Objective,
        on: a.objective_id == o.id,
        where: o.community_id == ^id,
        where: c.action_id == a.id,
        select: count(c.id)
      )

    query
    |> Repo.one()
    |> case do
      nil -> {:ok, 0}
      results -> {:ok, results}
    end
  end

  @doc """
  Fetch a single objective by id

  ## Parameters
  * id: the objective id
  """
  @spec get_objective(integer()) :: {:ok, Objective.t()} | {:error, term}
  def get_objective(id) do
    case Repo.get(Objective, id) do
      nil ->
        {:error, "No objective with id: #{id} found"}

      objective ->
        {:ok, objective}
    end
  end

  @doc """
  Updates an objective.

  ## Examples

      iex> update_objective(objective, %{is_completed: new_value})
      {:ok, %Objective{}}

      iex> update_objective(objective, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_objective(%Objective{} = objective, attrs) do
    objective
    |> Objective.changeset(attrs)
    |> Repo.update()
  end

  def complete_objective(objective_id) do
    case get_objective(objective_id) do
      {:ok, objective} ->
        now = NaiveDateTime.utc_now()
        update_objective(objective, %{is_completed: true, completed_at: now})

      error ->
        error
    end
  end
end
