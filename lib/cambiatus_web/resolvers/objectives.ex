defmodule CambiatusWeb.Resolvers.Objectives do
  @moduledoc """
  This module holds the implementation of the resolver for the objectives context
  """
  alias Absinthe.Relay.Connection
  alias Cambiatus.Commune.Community
  alias Cambiatus.Objectives
  alias Cambiatus.Objectives.{Action, Claim}

  @doc """
  Fetches a claim
  """
  @spec get_claim(map(), map(), map()) :: {:ok, Claim.t()} | {:error, term}
  def get_claim(_, %{id: id}, _) do
    Objectives.get_claim(id)
  end

  def get_analyzed_claims(
        _,
        %{community_id: community_id} = args,
        %{context: %{current_user: current_user}}
      ) do
    query = Objectives.analyzed_claims_query(community_id, current_user.account)
    count = Claim.count(query)

    query =
      if Map.has_key?(args, :filter) do
        args
        |> Map.get(:filter)
        |> Enum.reduce(query, fn
          {:claimer, claimer}, query ->
            Claim.with_claimer(query, claimer)

          {:status, status}, query ->
            Claim.with_status(query, status)

          {:direction, direction}, query ->
            Claim.ordered(query, direction)
        end)
      else
        Claim.ordered(query, :desc)
      end

    query
    |> Connection.from_query(&Cambiatus.Repo.all/1, args)
    |> case do
      {:ok, result} ->
        {:ok, Map.put(result, :count, Cambiatus.Repo.one(count))}

      default ->
        default
    end
  end

  def get_pending_claims(_, %{community_id: community_id} = args, %{
        context: %{current_user: current_user}
      }) do
    query = Objectives.pending_claims_query(community_id, current_user.account)
    count = Claim.count(query)

    query =
      if Map.has_key?(args, :filter) do
        args
        |> Map.get(:filter)
        |> Enum.reduce(query, fn
          {:claimer, claimer}, query ->
            Claim.with_claimer(query, claimer)

          {:status, status}, query ->
            Claim.with_status(query, status)

          {:direction, direction}, query ->
            Claim.ordered(query, direction)
        end)
      else
        Claim.ordered(query, :desc)
      end

    query
    |> Connection.from_query(&Cambiatus.Repo.all/1, args)
    |> case do
      {:ok, result} ->
        {:ok, Map.put(result, :count, Cambiatus.Repo.one(count))}

      default ->
        default
    end
  end

  @doc """
  Fetch a objective
  """
  @spec get_objective(map(), map(), map()) :: {:ok, map()} | {:error, term}
  def get_objective(_, params, _) do
    Objectives.get_objective(params.id)
  end

  @spec get_action_count(Cambiatus.Commune.Community.t(), any, any) :: {:ok, any}
  def get_action_count(%Community{} = community, _, _) do
    Objectives.get_action_count(community)
  end

  def get_claim_count(%Community{} = community, _, _) do
    Objectives.get_claim_count(community)
  end

  def get_claim_count(%Action{} = action, filter, _) do
    # Objectives.get_claim_count(action, filter)
    Objectives.get_claim_count(action, filter)
  end

  @spec complete_objective(map(), map(), map()) :: {:ok, map()} | {:error, String.t()}
  def complete_objective(_, %{id: id}, %{
        context: %{current_user: current_user}
      }) do
    Objectives.complete_objective(current_user, id)
  end
end
