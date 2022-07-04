defmodule CambiatusWeb.Resolvers.Commune do
  @moduledoc """
  This module holds the implementation of the resolver for the commune context
  use this to resolve any queries and mutations for the Commune context
  """

  alias Cambiatus.{Auth, Commune, Error, Shop, Social}
  alias Cambiatus.Commune.Community

  def search(_, _, %{context: %{current_community: current_community}}) do
    {:ok, current_community}
  end

  @doc """
  Fetches a single transfer
  """
  @spec get_transfer(map(), map(), map()) :: {:ok, Transfer.t()} | {:error, term}
  def get_transfer(_, %{id: id}, _) do
    Commune.get_transfer(id)
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

  def update_community(_, %{input: changes}, %{
        context: %{current_user: current_user, current_community: current_community}
      }) do
    Commune.update_community(current_community, current_user, changes)
    |> case do
      {:ok, _community} = ok ->
        ok

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, message: "Can't update community", details: Error.from(changeset)}

      {:error, reason} ->
        {:error, message: "Can't update community", details: reason}
    end
  end

  @doc """
  Collects all transfers from a community
  """
  @spec get_transfers(map(), map(), map()) :: {:ok, list(map())} | {:error, String.t()}
  def get_transfers(%Community{} = community, args, _) do
    {:ok, transfers} = Commune.get_transfers(community, args)
    {:ok, count} = Commune.get_transfers_count(community)

    result = Map.put(transfers, :parent, community)
    result = Map.put(result, :count, count)

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

  def domain_available(_, %{domain: domain}, _) do
    {:ok, %{exists: Commune.domain_available(domain)}}
  end

  def add_photos(_, %{symbol: symbol, urls: urls}, %{context: %{current_user: current_user}}) do
    Commune.add_photos(current_user, symbol, urls)
  end

  def set_highlighted_news(_, %{community_id: community_id} = args, %{
        context: %{current_user: current_user}
      }) do
    news_id = Map.get(args, :news_id)

    Commune.set_highlighted_news(community_id, news_id, current_user)
    |> case do
      {:ok, community} ->
        publish_highlighted_news_change(community.highlighted_news_id, community.symbol)
        {:ok, community}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, message: "Could not set highlighted news", details: Error.from(changeset)}

      {:error, reason} ->
        {:error, message: "Could not set highlighted news", details: reason}
    end
  end

  defp publish_highlighted_news_change(news_id, community_id) do
    news = if is_nil(news_id), do: nil, else: Social.get_news(news_id)

    Absinthe.Subscription.publish(
      CambiatusWeb.Endpoint,
      news,
      highlighted_news: community_id
    )
  end
end
