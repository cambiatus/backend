defmodule BeSpiralWeb.CommunityView do
  use BeSpiralWeb, :view

  def render("index.json", %{communities: communities}) do
    %{data: Enum.map(communities, &render("show.json", %{community: &1, objectives: []}))}
  end

  def render("show.json", %{community: c, objectives: objectives}) do
    render_symbol = fn sym ->
      sym
      |> String.split(",")
      |> List.last()
    end

    response = %{
      title: c["title"],
      symbol: render_symbol.(c["symbol"]),
      supply: c["supply"],
      subc_price: c["subc_price"],
      parentc: c["parentc"],
      min_balance: c["min_balance"],
      max_supply: c["max_supply"],
      logo: c["logo"],
      issuer: c["issuer"],
      inviter_reward: c["inviter_reward"],
      invited_reward: c["invited_reward"],
      description: c["description"],
      creator: c["creator"],
      allow_subc: c["allow_subc"],
      transfer_count: c["transfer_count"],
      member_count: c["member_count"]
    }

    response
    |> Map.put("objectives", objectives)
  end

  def render("members.json", %{members: members}) do
    %{data: members}
  end

  def render("transactions.json", %{transactions: transactions}) do
    %{data: transactions}
  end

  def render("invite.json", %{invites: _invites}) do
    %{result: "ok"}
  end
end
