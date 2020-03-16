defmodule Cambiatus.Auth do
  @moduledoc "Cambiatus Account Authentication and Signup Manager"

  import Ecto.Query

  alias Cambiatus.{
    Accounts,
    Accounts.User,
    Auth,
    Auth.Invitation,
    Auth.InvitationId,
    Commune.Network,
    Repo
  }

  @contract Application.get_env(:cambiatus, :contract)

  @doc """
  Login logic for Cambiatus when signing in with an invitationId
  """
  def sign_in(%{"account" => account}, invitation_id) do
    with %Invitation{} = invitation <- Auth.get_invitation(invitation_id),
         %User{} = user <- Accounts.get_user(account),
         {:ok, %{transaction_id: _}} <-
           @contract.netlink(user.account, invitation.creator_id, invitation.community_id),
         user <- Repo.preload(user, :communities) do
      {:ok, user}
    end
  end

  @doc """
  Login logic for Cambiatus.

  We check our demux/postgres database to see if have a entry for this user.
  """
  def sign_in(%{"account" => account}) do
    # Check params
    account
    |> Accounts.get_user()
    |> case do
      nil ->
        {:error, :not_found}

      user ->
        # Add user to Cambiatus if it isn't on it yet
        user = Repo.preload(user, :communities)

        user
        |> Map.get(:communities)
        |> Enum.any?(&(&1.symbol == @contract.cambiatus_community()))
        |> case do
          false ->
            # Add to cambiatus
            {:ok, _} = @contract.netlink(user.account, @contract.cambiatus_account())
            {:ok, user}

          _ ->
            {:ok, user}
        end
    end
  end

  @doc """
  Signs up a new user.

  It checks for existing invitations. If one can be found we create the user account on the blockchain,
  and netlink he/her to the community that has created the invitation

  If no invitation is found we assume the user is being invited to Cambiatus community.
  """
  def sign_up(%{
        "name" => name,
        "account" => account,
        "email" => email,
        "invitation_id" => invitation_id
      }) do
    with %Invitation{} = invitation <- Auth.get_invitation(invitation_id),
         nil <- Accounts.get_user(account),
         {:ok, user} <- Accounts.create_user(%{name: name, account: account, email: email}),
         {:ok, %{transaction_id: _txid}} <-
           @contract.netlink(user.account, invitation.creator_id, invitation.community_id) do
      user = user |> Repo.preload(:communities)
      {:ok, user}
    else
      %User{} ->
        {:error, :user_already_registered}

      _ ->
        {:error, :not_found}
    end
  end

  def sign_up(%{"account" => account} = params) do
    with nil <- Accounts.get_user(account),
         {:ok, %User{} = user} <- Accounts.create_user(params) do
      sign_in(%{"account" => user.account})
    else
      %User{} ->
        {:error, :user_already_registered}

      {:error, _} = error ->
        error
    end
  end

  def sign_up(_) do
    {:error, "Error parsing params"}
  end

  @doc """
  Returns the list of invitations.

  ## Examples

      iex> list_invitations()
      [%Invitation{}, ...]

  """
  def list_invitations,
    do: Invitation |> Repo.all() |> Repo.preload(:community) |> Repo.preload(:creator)

  @doc """
  Gets a single invitation.

  Raises `Ecto.NoResultsError` if the Invitation does not exist.

  ## Examples

      iex> get_invitation!(123)
      %Invitation{}

      iex> get_invitation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_invitation!(code) do
    {:ok, id} = InvitationId.decode(code)

    Invitation
    |> Repo.get!(id)
    |> Repo.preload(:community)
    |> Repo.preload(:creator)
  end

  @doc """
  Gets a single invitation.

  Returns `nil` if the Invitation does not exist.

  ## Examples

  iex> get_invitation!(123)
  %Invitation{}

  iex> get_invitation!(456)
  nil

  """
  def get_invitation(code) do
    {:ok, id} = InvitationId.decode(code)

    Invitation
    |> Repo.get(id)
    |> Repo.preload(:community)
    |> Repo.preload(:creator)
  end

  def user_invitations(%User{account: account}) do
    Repo.all(from(i in Invitation, where: i.creator_id == ^account))
  end

  @doc """
  Creates a invitation.

  ## Examples

      iex> create_invitation(%{field: value})
      {:ok, %Invitation{}}

      iex> create_invitation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_invitation(attrs \\ %{})

  def create_invitation(%{"community_id" => cmm_id, "creator_id" => c_id} = attrs) do
    # Check if creator belongs to the community
    if Repo.get_by(Network, account_id: c_id, community_id: cmm_id) == nil do
      {:error, "User don't belong to the community"}
    else
      # Check if there are existing invitations already
      with %Invitation{} = invitation <-
             Repo.get_by(Invitation, community_id: cmm_id, creator_id: c_id) do
        {:ok, invitation}
      else
        nil ->
          %Invitation{}
          |> Invitation.changeset(attrs)
          |> Repo.insert()
      end
    end
  end

  def create_invitation(_attrs) do
    {:error, "Can't parse arguments"}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invitation changes.

  ## Examples

      iex> change_invitation(invitation)
      %Ecto.Changeset{source: %Invitation{}}

  """
  def change_invitation(%Invitation{} = invitation) do
    Invitation.changeset(invitation, %{})
  end
end
