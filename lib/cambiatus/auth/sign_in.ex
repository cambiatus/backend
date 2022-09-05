defmodule Cambiatus.Auth.SignIn do
  @moduledoc """
  Do the Sign In operation
  """

  alias Cambiatus.{Accounts, Auth, Commune, Repo}
  alias Cambiatus.Accounts.User
  alias Cambiatus.Commune.Community

  @contract Application.compile_env(:cambiatus, :contract)

  @doc """
  Login logic for Cambiatus.
  We check our demux/postgres database to see if have a entry for this user.
  """
  def sign_in(account, password, community: community) do
    Sentry.Context.set_extra_context(%{account: account, community: community})

    with {:ok, %User{} = user} <- Accounts.get_user(account),
         true <- Accounts.verify_pass(account, password) do
      case {community.auto_invite, Commune.is_community_member?(community.symbol, account)} do
        # Community has auto invite and user is not in yet
        {true, false} ->
          {:ok, _txid} = netlink(user, community)
          Auth.delete_request(account)
          {:ok, user}

        # Already a member, nothing new to do
        {_, true} ->
          Auth.delete_request(account)
          {:ok, user}

        {false, false} ->
          {:error,
           "Sorry we can't add you to this community: #{community.symbol}, as it don't allow for auto invites, please provide an invitation"}
      end
    else
      {:error, reason} ->
        {:error, reason}

      false ->
        {:error, "Invalid password"}
    end
  end

  def sign_in(account, password, invitation_id: invitation_id) do
    Sentry.Context.set_extra_context(%{account: account, invitation_id: invitation_id})

    case Accounts.get_user(account) do
      {:error, _} ->
        {:error, :not_found}

      {:ok, user} ->
        if Accounts.verify_pass(account, password) do
          Auth.delete_request(account)

          {:ok, user}
          |> netlink(invitation_id)
        else
          {:error, :invalid_password}
        end
    end
  end

  def sign_in(_, _, []), do: {:error, :invalid_domain}

  def netlink(%User{} = user, %Community{} = community) do
    user_type =
      user
      |> Repo.preload(:kyc)
      |> Map.get(:kyc)
      |> case do
        nil ->
          "natural"

        kyc ->
          kyc.user_type
      end

    @contract.netlink(user.account, community.creator, community.symbol, user_type)
  end

  def netlink({:ok, user}, invitation_id) do
    with {:ok, invitation} <- Auth.get_invitation(invitation_id),
         {:ok, %{transaction_id: _}} <-
           @contract.netlink(user.account, invitation.creator_id, invitation.community_id) do
      {:ok, user}
    end
  end

  def netlink({:error, _} = error, _), do: error
end
