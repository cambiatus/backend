defmodule BeSpiral.Auth do
  @moduledoc "BeSpiral Account Authentication and Signup Manager"

  import Ecto.Query

  alias BeSpiral.Accounts
  alias BeSpiral.Accounts.User
  alias BeSpiral.Auth.Invitation
  alias BeSpiral.Chat
  alias BeSpiral.Commune
  alias BeSpiral.Mails.UserMail
  alias BeSpiral.Repo

  @contract Application.get_env(:bespiral, :contract)

  @doc """
  Login logic for BeSpiral.

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
        # Add user to BeSpiral if it isn't on it yet
        user = Repo.preload(user, :communities)

        user
        |> Map.get(:communities)
        |> Enum.any?(&(&1.symbol == @contract.bespiral_community()))
        |> case do
          false ->
            # Add to bespiral
            @contract.netlink(user.account, @contract.bespiral_account())

          _ ->
            :ok
        end

        try do
          {:ok, _user} = Chat.sign_in_or_up(user)
        rescue
          my_exception ->
            Sentry.capture_exception(my_exception, stacktrace: System.stacktrace())
            {:ok, user}
        end
    end
  end

  @doc """
  Signs up a new user.

  It checks for existing invitations. If one can be found we create the user account on the blockchain,
  and netlink he/her to the community that has created the invitation

  If no invitation is found we assume the user is being invited to BeSpiral community.
  """
  def sign_up(%{"name" => name, "account" => account, "invitation_id" => invitation_id}) do
    with %Invitation{} = invitation <-
           Repo.get_by(Invitation, id: invitation_id, accepted: false),
         nil <- Accounts.get_user(account),
         {:ok, user} <-
           Accounts.create_user(%{name: name, account: account, email: invitation.invitee_email}),
         %{transaction_id: _txid} <-
           @contract.netlink(user.account, invitation.inviter, invitation.community),
         {:ok, _invitation} <- invitation |> update_invitation(%{accepted: true}) do
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
  def list_invitations, do: Repo.all(Invitation)

  @doc """
  Gets a single invitation.

  Raises `Ecto.NoResultsError` if the Invitation does not exist.

  ## Examples

      iex> get_invitation!(123)
      %Invitation{}

      iex> get_invitation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_invitation!(id) do
    Repo.get!(Invitation, id)
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
  def get_invitation(id) do
    Repo.get(Invitation, id)
  end

  def user_invitations(%User{email: email}) when not is_nil(email) do
    Repo.all(from(i in Invitation, where: i.invitee_email == ^email and i.accepted == false))
  end

  @doc """
  Creates a invitation.

  ## Examples

      iex> create_invitation(%{field: value})
      {:ok, %Invitation{}}

      iex> create_invitation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_invitation(attrs \\ %{}) do
    %Invitation{}
    |> Invitation.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an invitation.

  ## Examples

  iex> update_invitation(invitation, %{field: new_value})
  {:ok, %Invitation{}}

  iex> update_invitation(invitation, %{field: bad_value})
  {:error, %Ecto.Changeset{}}

  """
  def update_invitation(%Invitation{} = invitation, attrs) do
    invitation
    |> Invitation.changeset(attrs)
    |> Repo.update()
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

  def create_invites(%{"inviter" => inviter, "invites" => emails, "symbol" => community}) do
    create_invites(community, inviter, emails)
  end

  def create_invites(community, inviter, emails) do
    x =
    emails
    |> String.split(",")
    |> Enum.map(
      &%{
        community: community,
        inviter: inviter,
        invitee_email: &1
      }
    )
    |> Enum.map(&create_invitation(&1))
    |> Enum.map(send_invite)
  end

  def send_invite(
        {:ok,
         %{id: id, community: community_symbol, inviter: inviter_account, invitee_email: email}}
      ) do
    community = Commune.get_community!(community_symbol)
    inviter = Accounts.get_user!(inviter_account)

    invite = %{
      community_name: community.name,
      inviter: inviter.name || inviter.account,
      id: to_string(id)
    }

    UserMail.invitation(email, invite)
  end

  def send_invite({:error, _reason} = err), do: err
end
