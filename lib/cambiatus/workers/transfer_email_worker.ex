defmodule Cambiatus.Workers.TransferEmailWorker do
  @moduledoc """
  Worker that send emails when a transfer is made.
  """

  use Oban.Worker,
    queue: :mailers,
    max_attempts: 3,
    tags: ["transfer"],
    unique: [period: 120]

  def perform(%Oban.Job{args: %{"transfer_id" => transfer_id}}) do
    case Cambiatus.Commune.get_transfer(transfer_id) do
      {:ok, transfer} ->
        CambiatusWeb.Email.transfer(transfer)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
