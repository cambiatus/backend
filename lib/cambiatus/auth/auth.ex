defmodule Cambiatus.Auth do
  @moduledoc "Cambiatus Account Authentication and Signup Manager"

  import Ecto.Query

  alias CambiatusWeb.AuthToken

  alias Cambiatus.{
    Accounts,
    Accounts.User,
    Commune.Network,
    Repo,
    Auth
  }

  alias Cambiatus.Auth.{
    Invitation,
    InvitationId,
    Ecdsa,
    Phrase,
    UserToken
  }

  @contract Application.get_env(:cambiatus, :contract)
  # @doc """
  # Login logic for Cambiatus.
  # We check our demux/postgres database to see if have a entry for this user.
  # """
  def sign_in(account, password) do
    account
    |> Accounts.get_user()
    |> case do
      nil ->
        {:error, :not_found}

      user ->
        if Accounts.verify_pass(account, password) do
          {:ok, user}
        else
          {:error, :invalid_password}
        end
    end
  end

  @doc """
  Login logic for Cambiatus when signing in with an invitationId
  """
  def sign_in(account, password, invitation_id) do
    account
    |> sign_in(password)
    |> netlink(invitation_id)
  end

  def gen_auth_phrase(user) do
    user
    |> create_phrase()
    |> create_session()
  end

  def create_phrase(user) do
    phrase = Phrase.generate()
    token = AuthToken.gen_token(%{phrase: phrase})

    %UserToken{}
    |> UserToken.changeset(%{phrase: phrase, token: token, context: "auth"}, user)
    |> Repo.insert()
    |> case do
      {:ok, _} -> {:ok, {user, phrase}}
      {:error, _err} -> {:error, "Phrase exists already"}
    end
  end

  def create_session({:error, _} = err), do: err

  def create_session({:ok, {user, phrase}}) do
    token = AuthToken.gen_token(%{account: user.account})

    %UserToken{}
    |> UserToken.changeset(%{token: token, context: "session"}, user)
    |> Repo.insert()
    |> case do
      {:ok, _} -> {:ok, {phrase, token}}
      {:error, _err} -> {:error, "Session exists already"}
    end
  end

  def verify(token) do
    token
    |> verify_session_token()
    |> get_account_from_token()
  end

  def verify_session_token(token) do
    get_user_token(%{token: token, filter: :session})
    |> case do
      user_token when is_map(user_token) ->
        {AuthToken.verify(user_token.token, 2 * 24 * 3600), user_token}

      nil ->
        {:error, "Session not found"}
    end
  end

  def get_account_from_token({{:ok, _}, user_token}) do
    Cambiatus.Accounts.get_user(user_token.user_id)
  end

  def get_account_from_token({{:error, _}, _}) do
    {:error, "Invalid session"}
  end

  def verify_session_token(account, token) do
    %{account: account, filter: :session}
    |> get_user_token()
    |> Map.values()
    |> Enum.member?(token)
    |> case do
      true ->
        AuthToken.verify(token, 2 * 24 * 3600)

      false ->
        delete_user_token(%{account: account, filter: :auth})
        {:error, "No session found"}
    end
  end

  def verify_signature(account, signature) do
    result =
      case get_user_token(%{account: account, filter: :auth}) do
        %{phrase: phrase} ->
          if Ecdsa.verify_signature(account, signature, phrase) do
            {:ok, Accounts.get_user(account)}
          else
            {:error, "Invalid signature"}
          end

        nil ->
          {:error, "No phrase found"}
      end

    delete_user_token(%{account: account, filter: :auth})
    result
  end

  def get_user_token(%{account: account, filter: :session}) do
    from("user_tokens",
      where: [context: "session", user_id: ^account],
      select: [:context, :user_id, :token]
    )
    |> Repo.one!()
  end

  def get_user_token(%{token: token, filter: :session}) do
    from("user_tokens",
      where: [context: "session", token: ^token],
      select: [:context, :user_id, :token]
    )
    |> Repo.one!()
  end

  def get_user_token(%{account: account, filter: :auth}) do
    from("user_tokens",
      where: [context: "auth", user_id: ^account],
      select: [:context, :user_id, :token, :phrase]
    )
    |> Repo.one!()
  end

  def delete_user_token(%{account: account, filter: :session}) do
    from("user_tokens",
      where: [context: "session", user_id: ^account]
    )
    |> Repo.delete_all()
  end

  def delete_user_token(%{account: account, filter: :auth}) do
    from("user_tokens",
      where: [context: "auth", user_id: ^account]
    )
    |> Repo.delete_all()
  end

  def delete_all_user_token() do
    [:session, :auth]
    |> Enum.each(&delete_all_user_token(&1))
  end

  def delete_all_user_token(:auth) do
    from("user_tokens",
      where: [context: "auth"]
    )
    |> Repo.delete_all()
  end

  def delete_all_user_token(:session) do
    from("user_tokens",
      where: [context: "session"]
    )
    |> Repo.delete_all()
  end

  def netlink({:ok, user}, invitation_id) do
    with {:ok, invitation} <- Auth.get_invitation(invitation_id),
         {:ok, %{transaction_id: _}} <-
           @contract.netlink(user.account, invitation.creator_id, invitation.community_id) do
      {:ok, user}
    end
  end

  def netlink({:error, _} = error, _), do: error

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
          {:ok, %Invitation{}} | {:error, :invitation_not_found} | {:error, :decode_failed}
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
