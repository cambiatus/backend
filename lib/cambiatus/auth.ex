defmodule Cambiatus.Auth do
  @moduledoc "Cambiatus Account Authentication and Signup Manager"

  import Ecto.Query

  alias Cambiatus.Auth.{Invitation, InvitationId, Request, Session}
  alias Cambiatus.{Accounts, Accounts.User, Commune.Network, Repo}

  @doc """
  Returns the list of invitations.

  ## Examples

      iex> list_invitations()
      [%Invitation{}, ...]

  """
  def list_invitations do
    Invitation |> Repo.all() |> Repo.preload(:community) |> Repo.preload(:creator)
  end

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

  def get_invitation(code) do
    case InvitationId.decode(code) do
      {:ok, id} ->
        invite =
          Invitation
          |> Repo.get(id)
          |> Repo.preload(:community)
          |> Repo.preload(:creator)

        if invite do
          {:ok, invite}
        else
          {:error, "Invitation not found"}
        end

      {:error, _} ->
        {:error, "Invitation not found"}
    end
  end

  @doc """
  Finds a single invitation. You need to send an invitation code

  Returns `{:error, :invitation_not_found}` if the Invitation does not exist.

  ## Examples

  iex> find_invitation("aALJc")
  {:ok, %Invitation{}}

  iex> find_invitation("aa")
  {:error, :invitation_not_found}

  iex> find_invitation("not valid invitation code")
  {:error, :decode_failed}
  """
  @spec find_invitation(binary) ::
          {:ok, Invitation.t()} | {:error, :invitation_not_found} | {:error, :decode_failed}
  def find_invitation(code) do
    case InvitationId.decode(code) do
      {:ok, id} ->
        Invitation
        |> Repo.get(id)
        |> Repo.preload(:community)
        |> Repo.preload(:creator)
        |> case do
          %Invitation{} = invitation ->
            {:ok, invitation}

          nil ->
            {:error, :invitation_not_found}
        end

      _ ->
        {:error, :decode_failed}
    end
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
      case Repo.get_by(Invitation, community_id: cmm_id, creator_id: c_id) do
        %Invitation{} = invitation ->
          {:ok, invitation}

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

  @doc """
  Returns an request for session or an error.any()

  ##Examples

      iex> create_request(account)
      {:ok, %Request{}}

      iex> create_request(invalid_account)
      {:error, "Could not find user"}
  """
  def create_request(account, ip_address) do
    account
    |> Accounts.get_user()
    |> case do
      {:error, reason} ->
        {:error, reason}

      {:ok, user} ->
        params = %{
          user_id: user.account,
          phrase: :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64),
          ip_address: ip_address
        }

        get_request(user.account)
        |> case do
          nil -> %Request{}
          request -> request
        end
        |> Request.changeset(params)
        |> Repo.insert_or_update()
    end
  end

  def get_request(account) do
    Repo.get_by(Request, user_id: account)
  end

  def get_valid_request(account) do
    Request
    |> Request.from_user(account)
    |> Request.not_expired()
    |> Repo.one()
  end

  def delete_expired_requests do
    Request
    |> Request.expired()
    |> Repo.delete_all()
  end

  def create_session(params) do
    %Session{}
    |> Session.changeset(params)
    |> Repo.insert()
  end

  def delete_request(account) do
    Request
    |> Request.from_user(account)
    |> Repo.delete_all()
  end
end
