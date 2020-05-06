defmodule Cambiatus.Commune do
  @moduledoc """
  The Commune context. Handles everything related to communities. Network, Transfers, Details, Indexes, etc
  """

  import Ecto.Query
  alias Absinthe.Relay.Connection

  alias Cambiatus.{
    Accounts.User,
    Commune.Action,
    Commune.AvailableSale,
    Commune.Check,
    Commune.Community,
    Commune.Claim,
    Commune.Network,
    Commune.Objective,
    Commune.SaleHistory,
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
          |> where([a], a.creator_id == ^account)

        {:validator, account}, query ->
          query
          |> join(:inner, [a], v in Validator,
            on: a.id == v.action_id and v.validator_id == ^account
          )

        {:is_completed, is_completed}, query ->
          query
          |> where([a], a.is_completed == ^is_completed)

        {:verification_type, verification_type}, query ->
          query
          |> where([a], a.verification_type == ^verification_type)

        _, query ->
          query
      end)
      |> order_by([a], a.created_at)

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
  Fetch a sale history record

  ## Parameters
  * id: id of the history to be fetched
  """
  @spec get_sale_history(integer()) :: {:ok, SaleHistory.t()} | {:error, term}
  def get_sale_history(id) do
    case Repo.get(SaleHistory, id) do
      nil ->
        {:error, "No SaleHistory record with the id: #{id} found"}

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
  Fetch a validators claims

  ## Paramters
  * account: the validator in question's account name
  """
  @spec get_validator_claims(String.t()) :: {:ok, list(Claim.t())} | {:error, term}
  def get_validator_claims(account) do
    query_action =
      from(c in Claim,
        join: a in Action,
        on: a.id == c.action_id,
        join: v in Validator,
        on: v.action_id == c.action_id,
        left_join: ch in Check,
        on: ch.claim_id == c.id,
        where: c.is_verified == ^false,
        where: is_nil(ch.claim_id),
        where: v.validator_id == ^account
      )

    available_claims = Repo.all(query_action)

    {:ok, available_claims}
  end

  @doc """
  Fetch a validators claims

  ## Paramters
  * account: the validator in question's account name
  * community_id: Community ID, to get only claims from a given community
  """
  @spec get_validator_claims_on_community(map()) :: {:ok, list(Claim.t())} | {:error, term}
  def get_validator_claims_on_community(
        %{input: %{symbol: community_id, validator: account, all: all}} = args
      ) do
    query_action =
      if all do
        from(c in Claim,
          join: a in Action,
          on: a.id == c.action_id,
          join: o in Objective,
          on: o.id == a.objective_id,
          join: v in Validator,
          on: v.action_id == c.action_id,
          left_join: ch in Check,
          on: ch.claim_id == c.id,
          where: v.validator_id == ^account,
          where: o.community_id == ^community_id,
          order_by: [desc: c.created_at]
        )
      else
        from(c in Claim,
          join: a in Action,
          on: a.id == c.action_id,
          join: o in Objective,
          on: o.id == a.objective_id,
          join: v in Validator,
          on: v.action_id == c.action_id,
          left_join: ch in Check,
          on: ch.claim_id == c.id,
          where: c.is_verified == false,
          where: fragment("?.claim_id is NULL or ?.validator_id != ?", ch, ch, ^account),
          where: v.validator_id == ^account,
          where: o.community_id == ^community_id,
          order_by: [desc: c.created_at]
        )
      end

    query_action
    |> Connection.from_query(&Repo.all/1, args |> Map.drop([:input]))
  end

  @doc """
  Fetch sale

  ## Parameters
  * id: the id of the sale in question
  """
  @spec get_sale(integer()) :: {:ok, AvailableSale.t()} | {:error, term}
  def get_sale(id) do
    case Repo.get(AvailableSale, id) do
      nil ->
        {:error, "Sale #{id} not found"}

      val ->
        {:ok, val}
    end
  end

  @doc """
  Gets all sales for a user
  """
  @spec all_sales_for(map()) :: {:ok, list(AvailableSale.t())} | {:error, term}
  def all_sales_for(%User{account: acc}) do
    query =
      AvailableSale
      |> where([s], s.creator_id != ^acc)
      |> order_by([s], desc: s.created_at)

    sales =
      query
      |> Repo.all()

    {:ok, sales}
  end

  @doc """
  Collect all sales that belong to a user
  """
  @spec get_user_sales(map()) :: {:ok, list(AvailableSale.t())} | {:error, term}
  def get_user_sales(%User{account: acc}) do
    query =
      AvailableSale
      |> where([s], s.creator_id == ^acc)
      |> order_by([s], desc: s.created_at)

    sales =
      query
      |> Repo.all()

    {:ok, sales}
  end

  @doc """
  Collect all sales from a user's communities
  """
  @spec get_user_communities_sales(map()) :: {:ok, list(AvailableSale.t())} | {:error, term()}
  def get_user_communities_sales(%User{account: acc} = usr) do
    %{communities: cms} = Repo.preload(usr, :communities)

    symbols = Enum.map(cms, fn %{symbol: s} -> s end)

    query =
      AvailableSale
      |> where([s], s.creator_id != ^acc)
      |> where([s], s.community_id in ^symbols)
      |> order_by([s], desc: s.created_at)

    sales =
      query
      |> Repo.all()

    {:ok, sales}
  end

  @spec get_community_sales(Int.t(), String.t()) ::
          {:ok, list(AvailableSale.t())} | {:error, term()}
  def get_community_sales(community_id, acc) do
    query =
      AvailableSale
      |> where([s], s.community_id == ^community_id)
      |> where([s], s.creator_id != ^acc)
      |> order_by([s], desc: s.created_at)

    sales = Repo.all(query)

    {:ok, sales}
  end

  @spec get_sales_history :: {:ok, list(map())} | {:error, term}
  def get_sales_history() do
    {:ok, Repo.all(SaleHistory)}
  end

  @doc """
  Provided with a profile this collects all transfers belong to the user
  """
  @spec get_transfers(map(), map()) :: {:ok, list(map())} | {:error, String.t()}
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

  def get_sale_count(%Community{symbol: id}) do
    query =
      from(s in Cambiatus.Commune.Sale,
        where: s.community_id == ^id,
        select: count(s.id)
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
      from(a in Cambiatus.Commune.Action,
        join: o in Cambiatus.Commune.Objective,
        on: a.objective_id == o.id,
        where: o.community_id == ^id,
        select: count(a.id)
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
end
