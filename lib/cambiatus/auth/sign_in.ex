defmodule Cambiatus.Auth.SignIn do
  @moduledoc """
  Do the Sign In operation
  """

  alias Cambiatus.{Accounts, Auth}

  @contract Application.compile_env(:cambiatus, :contract)

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

  def netlink({:ok, user}, invitation_id) do
    with {:ok, invitation} <- Auth.get_invitation(invitation_id),
         {:ok, %{transaction_id: _}} <-
           @contract.netlink(user.account, invitation.creator_id, invitation.community_id) do
      {:ok, user}
    end
  end

  def netlink({:error, _} = error, _), do: error
end
