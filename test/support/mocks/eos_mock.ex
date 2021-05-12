defmodule Cambiatus.EosMock do
  @moduledoc "Mocked implementation of Cambiatus.Eos"
  @behaviour Cambiatus.Eos

  alias Cambiatus.Commune

  @cambiatus_community "BES"
  @cambiatus_account "cambiatustes"

  def create_account(_public_key, _account) do
    {:ok, %{}}
  end

  def netlink(new_user, inviter, community \\ @cambiatus_community, user_type \\ "natural") do
    {:ok, _network} =
      Commune.create_network(%{
        account_id: new_user,
        community_id: community,
        invited_by_id: inviter,
        user_type: user_type
      })

    {:ok, %{transaction_id: "mockedtransactionid"}}
  end

  def cambiatus_community, do: @cambiatus_community
  def cambiatus_account, do: @cambiatus_account
end
