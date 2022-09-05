defmodule Cambiatus.Workers.DigestEmailWorker do
  @moduledoc """
  Handles sending news digest email
  """
  use Oban.Worker,
    queue: :mailers,
    max_attempts: 3,
    tags: ["digest"],
    unique: [period: 120]

  alias Cambiatus.{Accounts, Commune}

  def perform(%Oban.Job{args: %{"community_id" => community_id, "account" => account}}) do
    with {:ok, community} <- Commune.get_community(community_id),
         {:ok, member} <- Accounts.get_user(account) do
      CambiatusWeb.Email.monthly_digest(community, member)
    else
      {:error, reason} ->
        {:error, reason}
    end
  end
end
