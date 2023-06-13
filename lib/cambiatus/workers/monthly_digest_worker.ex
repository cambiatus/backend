defmodule Cambiatus.Workers.MonthlyDigestWorker do
  @moduledoc """
  Handles monthly news digest by creating workers to send emails
  """
  use Oban.Worker, queue: :monthly_digest

  alias Cambiatus.Accounts.User
  alias Cambiatus.Commune.Community
  alias Cambiatus.Repo
  alias Cambiatus.Social.News
  alias Cambiatus.Workers.DigestEmailWorker
  alias Ecto.Multi

  def perform(_) do
    Community
    |> Community.with_news_enabled()
    |> Repo.all()
    |> Repo.preload([
      [news: News.last_thirty_days()],
      [members: User.accept_digest()],
      :subdomain
    ])
    |> Enum.filter(&Enum.any?(&1.news))
    |> Enum.reduce(Multi.new(), fn community, multi ->
      Enum.reduce(community.members, multi, fn member, multi ->
        Oban.insert(
          multi,
          "#{community.symbol}-#{member.account}",
          DigestEmailWorker.new(%{community_id: community.symbol, account: member.account})
        )
      end)
    end)
    |> Repo.transaction()
    |> case do
      {:error, stage, _, _} -> {:error, stage}
      any -> any
    end
  end
end
