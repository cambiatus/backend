defmodule Cambiatus.Auth.SignIn do
  @moduledoc """
  Do the Sign In operation
  """

  alias Cambiatus.{Accounts, Auth, Commune, Repo}
  alias Cambiatus.Accounts.User
  alias Cambiatus.Commune.Community

  @contract Application.compile_env(:cambiatus, :contract)

  # @doc """
  # Login logic for Cambiatus.

  # We check our demux/postgres database to see if have a entry for this user.
  # # """
  # def sign_in(account, password, domain: domain) do
  #   with {:ok, community} <- Commune.get_community_by_subdomain(domain),
  #        {true, _} <- {community.auto_invite, community},
  #        %User{} = user <- Accounts.get_user(account),
  #        true <- Accounts.verify_pass(account, password),
  #        {:ok, _} <- netlink(user, community) do
  #     {:ok, user}
  #   else
  #     {:error, _reason} = error ->
  #       error

  #     {false, community} ->
  #       {:error,
  #        "Sorry we can't add you to this community: #{community.symbol}, as it don't allow for auto invites, please provide an invitation"}

  #     nil ->
  #       {:error, "Account not found"}

  #     false ->
  #       {:error, "Invalid password"}
  #   end
  # end

  def sign_in(account, password, domain: domain) do
    with {:ok, %Community{} = community} <- Commune.get_community_by_subdomain(domain),
         %User{} = user <- Accounts.get_user(account),
         true <- Accounts.verify_pass(account, password) do
      case {community.auto_invite, Commune.is_community_member?(community.symbol, account)} do
        # Community has auto invite and user is not in yet
        {true, false} ->
          {:ok, _txid} = netlink(user, community)
          {:ok, user}

        # Already a member, nothing new to do
        {_, true} ->
          {:ok, user}

        {false, false} ->
          {:error,
           "Sorry we can't add you to this community: #{community.symbol}, as it don't allow for auto invites, please provide an invitation"}
      end
    else
      {:error, _reason} = error ->
        error

      nil ->
        {:error, "Account not found"}

      false ->
        {:error, "Invalid password"}
    end
  end

  @doc """
  Login logic for Cambiatus when signing in with an invitationId
  """
  def sign_in(account, password, invitation_id: invitation_id) do
    case Accounts.get_user(account) do
      nil ->
        {:error, :not_found}

      user ->
        if Accounts.verify_pass(account, password) do
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
