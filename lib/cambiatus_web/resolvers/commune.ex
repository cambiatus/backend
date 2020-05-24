defmodule CambiatusWeb.Resolvers.Commune do
  @moduledoc """
  This module holds the implementation of the resolver for the commune context
  use this to resolve any queries and mutations for the Commune context
  """
  alias Absinthe.Relay.Connection

  alias Cambiatus.{
    Accounts,
    Auth,
    Commune
  }

  alias Cambiatus.Commune.{
    Community
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

  def get_claims_analysis_history(_, %{input: %{symbol: id, account: account}} = args, _) do
    query = Commune.claim_analysis_history_query(id, account)
    Connection.from_query(query, &Cambiatus.Repo.all/1, args)
  end

  def get_claims_analysis(_, %{input: %{symbol: id, account: account}} = args, _) do
    query = Commune.claim_analysis_query(id, account)
    Connection.from_query(query, &Cambiatus.Repo.all/1, args)
  end

  @doc """
  Fetch a sale from the database
  """
  @spec get_sale(map(), map(), map()) :: {:ok, map()} | {:error, term}
  def get_sale(_, %{input: params}, _) do
    Commune.get_sale(params.id)
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
  Collects a user's, or community's or the entirety of sales on the platform
  """
  @spec get_sales(map(), map(), map()) :: {:ok, list(map())} | {:error, :string}
  def get_sales(parent, params, resolution)

  def get_sales(_, %{input: %{community_id: symbol, account: account}}, _) do
    with {:ok, sales} <- Commune.get_community_sales(symbol, account) do
      {:ok, sales}
    end
  end

  def get_sales(_, %{input: %{account: acct}}, _) do
    with {:ok, profile} <- Accounts.get_account_profile(acct),
         {:ok, sales} <- Commune.get_user_sales(profile) do
      {:ok, sales}
    end
  end

  def get_sales(_, %{input: %{communities: sym}}, _) do
    with {:ok, commune} <- Accounts.get_account_profile(sym),
         {:ok, sales} <- Commune.get_user_communities_sales(commune) do
      {:ok, sales}
    end
  end

  def get_sales(_, %{input: %{all: acct}}, _) do
    with {:ok, profile} <- Accounts.get_account_profile(acct),
         {:ok, sales} <- Commune.all_sales_for(profile) do
      {:ok, sales}
    end
  end

  def get_sales_history(_, _, _) do
    Commune.get_sales_history()
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

  def get_network(%Community{} = community, _, _) do
    {:ok, Commune.list_community_network(community.symbol)}
  end

  def get_members_count(%Community{} = community, _, _) do
    Commune.get_members_count(community)
  end

  def get_transfer_count(%Community{} = community, _, _) do
    Commune.get_transfer_count(community)
  end

  def get_action_count(%Community{} = community, _, _) do
    Commune.get_action_count(community)
  end

  def get_sale_count(%Community{} = community, _, _) do
    Commune.get_sale_count(community)
  end

  @doc "Collect an invite"
  @spec get_invitation(map(), map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_invitation(_, %{input: %{id: id}}, _) do
    {:ok, Auth.get_invitation(id)}
  end
end
