defmodule CambiatusWeb.Resolvers.Commune do
  @moduledoc """
  This module holds the implementation of the resolver for the commune context
  use this to resolve any queries and mutations for the Commune context
  """
  alias Absinthe.Relay.Connection

  alias Cambiatus.{
    Auth,
    Commune,
    Commune.Community,
    Shop
  }

  @doc """
  Fetches a single transfer
  """
  @spec get_transfer(map(), map(), map()) :: {:ok, Transfer.t()} | {:error, term}
  def get_transfer(_, %{input: %{id: id}}, _) do
    Commune.get_transfer(id)
  end

  @doc """
  Fetches a claim
  """
  @spec get_claim(map(), map(), map()) :: {:ok, Claim.t()} | {:error, term}
  def get_claim(_, %{input: %{id: id}}, _) do
    Commune.get_claim(id)
  end

  def get_claims_analysis_history(
        _,
        %{input: %{symbol: id, account: account}} = args,
        _
      ) do
    query = Commune.claim_analysis_history_query(id, account)

    query =
      case Map.get(args[:input], :filter) do
        nil ->
          query

        filter ->
          case filter do
            %{claimer: claimer, status: status} when claimer != "" and status != "claimer" ->
              # add necessary where
              query
              |> Commune.claim_filter_claimer(claimer)
              |> Commune.claim_filter_status(status)

            %{claimer: claimer} ->
              query |> Commune.claim_filter_claimer(claimer)

            %{status: status} ->
              query |> Commune.claim_filter_status(status)

            _ ->
              query
          end
      end

    Connection.from_query(query, &Cambiatus.Repo.all/1, args)
  end

  def get_claims_analysis(_, %{input: %{symbol: id, account: account}} = args, _) do
    query = Commune.claim_analysis_query(id, account)
    Connection.from_query(query, &Cambiatus.Repo.all/1, args)
  end

  @doc """
  Fetch a objective
  """
  @spec get_objective(map(), map(), map()) :: {:ok, map()} | {:error, term}
  def get_objective(_, %{input: params}, _) do
    Commune.get_objective(params.id)
  end

  @doc """
  Collects all of the communities
  """
  @spec get_communities(map(), map(), map()) :: {:ok, list(map())}
  def get_communities(_, _, _) do
    Commune.list_communities()
  end

  @doc """
  Find a single community
  """
  @spec find_community(map(), map(), map()) :: {:ok, map()} | {:error, term()}
  def find_community(_, %{symbol: sym}, _) do
    Commune.get_community(sym)
  end

  @doc """
  Collects all transfers from a community
  """
  @spec get_transfers(map(), map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%Community{} = community, args, _) do
    {:ok, transfers} = Commune.get_transfers(community, args)

    result =
      transfers
      |> Map.put(:parent, community)

    {:ok, result}
  end

  @spec get_network(Cambiatus.Commune.Community.t(), any, any) :: {:ok, any}
  def get_network(%Community{} = community, _, _) do
    {:ok, Commune.list_community_network(community.symbol)}
  end

  def get_members_count(%Community{} = community, _, _) do
    Commune.get_members_count(community)
  end

  def get_transfer_count(%Community{} = community, _, _) do
    Commune.get_transfer_count(community)
  end

  @spec get_action_count(Cambiatus.Commune.Community.t(), any, any) :: {:ok, any}
  def get_action_count(%Community{} = community, _, _) do
    Commune.get_action_count(community)
  end

  def get_product_count(%Community{} = community, _, _) do
    Shop.community_product_count(community.symbol)
  end

  @doc "Collect an invite"
  @spec get_invitation(map(), map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_invitation(_, %{input: %{id: id}}, _) do
    Auth.get_invitation(id)
  end

  @spec complete_objective(map(), map(), map()) :: {:ok, map()} | {:error, String.t()}
  def complete_objective(_, %{input: %{objective_id: id}}, _) do
    Commune.complete_objective(id)
  end
end
