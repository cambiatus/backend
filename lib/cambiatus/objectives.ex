defmodule Cambiatus.Objectives do
  @moduledoc """
  The Objectives context. Handles everything related to objectives. Actions, Claims, Objectives, Checks, Validators etc
  """

  import Ecto.Query

  alias Cambiatus.Commune.Community
  alias Cambiatus.Objectives.{Action, Claim, Objective, Validator}
  alias Cambiatus.Repo

  @spec data :: Dataloader.Ecto.t()
  def data(params \\ %{}), do: Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)

  def query(Objective, _) do
    Objective
    |> order_by([o], desc: o.created_at, asc: o.completed_at)
  end

  def query(Action, %{input: filters}) do
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
  end

  def query(Action, %{query: query}) do
    Action
    |> Action.search(query)
    |> Action.available()
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
    |> Claim.newer_first()
  end

  def query(queryable, _params) do
    queryable
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
  @spec pending_claims_query(term, term) :: Ecto.Query.t()
  def pending_claims_query(community_id, account) do
    Claim
    |> join(:left, [c], a in assoc(c, :action))
    |> join(:left, [c, a], o in assoc(a, :objective))
    |> join(:left, [c, a], v in Validator, on: v.action_id == c.action_id)
    |> where(
      [c, a, o, v],
      o.community_id == ^community_id and
        v.validator_id == ^account and
        a.is_completed == false and
        not (a.usages > 0 and a.usages_left == 0) and
        (is_nil(a.deadline) or fragment("NOW()") < a.deadline) and
        c.status == "pending" and
        fragment(
          "select count(*) from checks b where b.claim_id = ?.id and b.validator_id = ?",
          c,
          ^account
        ) == 0
    )
  end

  @doc """
  Fetch all claims that the specified `account` is an analyser and already voted.

  ## Params
  * community_id: String with the community symbol
  * account: String. account from the user that voted already
  """
  @spec analyzed_claims_query(term, term) :: Ecto.Query.t()
  def analyzed_claims_query(community_id, account) do
    Claim
    |> join(:left, [c], a in assoc(c, :action))
    |> join(:left, [c, a], o in assoc(a, :objective))
    |> join(:left, [c, a], v in Validator, on: v.action_id == c.action_id)
    |> where([_, _, o], o.community_id == ^community_id)
    |> where([_, _, _, ch], ch.validator_id == ^account)
    |> where(
      [claim, _, _, _],
      fragment(
        "select count(*) from checks b where b.claim_id = ?.id and b.validator_id = ?",
        claim,
        ^account
      ) > 0
    )
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

  def get_claim_count(%Action{} = action, filter \\ %{}) do
    query = from(c in Claim, where: c.action_id == ^action.id, select: count(c.id))

    query =
      if Map.has_key?(filter, :status) do
        Claim.with_status(query, Map.get(filter, :status))
      else
        query
      end

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

  def complete_objective(current_user, objective_id) do
    case get_objective(objective_id) do
      {:ok, objective} ->
        objective = Repo.preload(objective, :community)

        if objective.community.creator == current_user.account do
          now = NaiveDateTime.utc_now()
          update_objective(objective, %{is_completed: true, completed_at: now})
        else
          {:error, "Unauthorized"}
        end

      error ->
        error
    end
  end
end
