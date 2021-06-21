defmodule CambiatusWeb.Resolvers.Commune do
  @moduledoc """
  This module holds the implementation of the resolver for the commune context
  use this to resolve any queries and mutations for the Commune context
  """
  alias Absinthe.Relay.Connection

  alias Cambiatus.{Auth, Commune, Shop}
  alias Cambiatus.Commune.{Claim, Community}

  def search(_, %{community_id: symbol}, _) do
    Commune.get_community(symbol)
  end

  @doc """
  Fetches a single transfer
  """
  @spec get_transfer(map(), map(), map()) :: {:ok, Transfer.t()} | {:error, term}
  def get_transfer(_, %{id: id}, _) do
    Commune.get_transfer(id)
  end

  @doc """
  Fetches a claim
  """
  @spec get_claim(map(), map(), map()) :: {:ok, Claim.t()} | {:error, term}
  def get_claim(_, %{input: %{id: id}}, _) do
    Commune.get_claim(id)
  end

  def get_analyzed_claims(
        _,
        %{community_id: community_id} = args,
        %{context: %{current_user: current_user}}
      ) do
    query = Commune.analyzed_claims_query(community_id, current_user.account)
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
    query = Commune.pending_claims_query(community_id, current_user.account)
    count = Claim.count(query)

    query =
      if Map.has_key?(args, :filter) do
        args
        |> Map.get(:filter)
        |> Enum.reduce(query, fn
          {:claimer, claimer}, query ->
            Claim.with_claimer(query, claimer)

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

  def find_community(_, %{symbol: _, subdomain: _}, _) do
    {:error, "please use symbol or subdomain"}
  end

  def find_community(_, %{symbol: sym}, _) do
    Commune.get_community(sym)
  end

  def find_community(_, %{subdomain: subdomain}, _) do
    Commune.get_community_by_subdomain(subdomain)
  end

  def find_community(%Cambiatus.Auth.Invitation{} = invite, _, _) do
    {:ok, invite.community}
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

  @spec get_network(Community.t(), any, any) :: {:ok, any}
  def get_network(%Community{} = community, _, _) do
    {:ok, Commune.list_community_network(community.symbol)}
  end

  def get_validators(%Community{} = community, _, _) do
    {:ok, Commune.community_validators(community.symbol)}
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

  def get_claim_count(%Community{} = community, _, _) do
    Commune.get_claim_count(community)
  end

  def get_product_count(%Community{} = community, _, _) do
    Shop.community_product_count(community.symbol)
  end

  def get_order_count(%Community{} = community, _, _) do
    Shop.community_order_count(community.symbol)
  end

  @doc "Collect an invite"
  @spec get_invitation(map(), map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_invitation(_, %{id: id}, _) do
    Auth.get_invitation(id)
  end

  @spec complete_objective(map(), map(), map()) :: {:ok, map()} | {:error, String.t()}
  def complete_objective(_, %{input: %{objective_id: id}}, %{
        context: %{current_user: current_user}
      }) do
    Commune.complete_objective(current_user, id)
  end

  def domain_available(_, %{domain: domain}, _) do
    {:ok, %{exists: Commune.domain_available(domain)}}
  end

  def add_photos(_, %{symbol: symbol, urls: urls}, %{context: %{current_user: current_user}}) do
    Commune.add_photos(current_user, symbol, urls)
  end
end
