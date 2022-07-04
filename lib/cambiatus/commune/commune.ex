defmodule Cambiatus.Commune do
  @moduledoc """
  The Commune context. Handles everything related to communities. Network, Transfers, Details, Indexes, etc
  """

  import Ecto.Query

  alias Absinthe.Relay.Connection
  alias Cambiatus.{Accounts.User, Repo, Social}

  alias Cambiatus.Commune.{
    Community,
    CommunityPhotos,
    Network,
    Subdomain,
    Transfer
  }

  alias Cambiatus.Objectives.{Objective, Action, Validator}

  @spec data :: Dataloader.Ecto.t()
  def data(params \\ %{}), do: Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)

  def query(CommunityPhotos, _params) do
    CommunityPhotos
    |> order_by([cp], desc: cp.inserted_at)
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
  Provided with a profile this collects all transfers belong to the user
  Given a community this collects all transfers belonging to the community
  """
  def get_transfers(%User{account: account}, pagination_args) do
    Transfer
    |> where([t], t.from_id == ^account or t.to_id == ^account)
    |> get_transfers_from(pagination_args)
  end

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
    case Repo.get_by(Community, symbol: sym) do
      nil ->
        {:error, "No community exists with the symbol: #{sym}"}

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

  def update_community({:error, _} = error), do: error
  def update_community({:error, _} = error, _), do: error
  def update_community({:ok, community}, attrs), do: update_community(community, attrs)

  def update_community(%Community{} = community, attrs) do
    community
    |> Community.changeset(attrs)
    |> Repo.update()
  end

  def update_community(%Community{} = current_community, current_user, attrs) do
    current_community
    |> check_user_authorization(current_user)
    |> update_community(attrs)
  end

  def update_community(community_id, current_user, attrs) do
    community_id
    |> get_community()
    |> case do
      {:ok, community} ->
        update_community(community, current_user, attrs)

      {:error, error} ->
        {:error, error}
    end
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
    community_id
    |> Network.by_community()
    |> Repo.all()
  end

  def is_community_member?(community_id, account) do
    Network
    |> Network.by_community(community_id)
    |> Network.by_user(account)
    |> Repo.all()
    |> Enum.any?()
  end

  def is_community_admin?(%Community{} = community, account) do
    community.creator == account
  end

  def is_community_admin?(community_id, account) do
    case Repo.get(Community, community_id) do
      nil ->
        false

      community ->
        is_community_admin?(community, account)
    end
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
  Get transfer count, depending on a community or an user
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

  def add_photos(current_user, symbol, urls) do
    case get_community(symbol) do
      {:ok, community} ->
        if community.creator == current_user.account do
          community
          |> Community.save_photos(urls)
          |> case do
            {:ok, _} = success -> success
            {:error, _} = error -> error
          end
        else
          {:error, "Unauthorized"}
        end

      {:error, _} = error ->
        error
    end
  end

  def domain_available(domain) do
    Repo.get_by(Subdomain, name: domain) != nil
  end

  def get_community_by_subdomain(subdomain) do
    Community
    |> Community.by_subdomain(subdomain)
    |> Repo.one()
    |> case do
      nil ->
        {:error, "No community found using the domain #{subdomain}"}

      found ->
        {:ok, found}
    end
  end

  def set_highlighted_news(community_id, news_id, current_user \\ nil) do
    community_id
    |> get_community
    |> check_user_authorization(current_user)
    |> case do
      {:error, error} ->
        {:error, error}

      {:ok, community} ->
        if is_nil(news_id) || Social.news_from_community?(news_id, community.symbol) do
          update_community(community, %{highlighted_news_id: news_id})
        else
          {:error, "News does not belong to community"}
        end
    end
  end

  def set_highlighted_news(community_id, news_id, current_user) do
    community_id
    |> get_community()
    |> case do
      {:ok, current_community} ->
        set_highlighted_news(current_community, news_id, current_user)

      {:error, error} ->
        {:error, error}
    end
  end

  defp check_user_authorization(community, nil), do: {:ok, community}

  defp check_user_authorization(current_community, current_user) do
    if current_community.creator == current_user.account do
      {:ok, current_community}
    else
      {:error, "Unauthorized"}
    end
  end
end
