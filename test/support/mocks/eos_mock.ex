defmodule BeSpiral.EosMock do
  @moduledoc "Mocked implementation of BeSpiral.Eos"
  @behaviour BeSpiral.Eos

  alias BeSpiral.Commune

  @bespiral_community "BES"
  @bespiral_account "bespiraltest"

  def netlink(new_user, inviter, community \\ @bespiral_community) do
    {:ok, _network} =
      Commune.create_network(%{
        account_id: new_user,
        community_id: community,
        invited_by_id: inviter
      })

    %{transaction_id: "mockedtransactionid"}
  end

  def bespiral_community, do: @bespiral_community
  def bespiral_account, do: @bespiral_account
end
