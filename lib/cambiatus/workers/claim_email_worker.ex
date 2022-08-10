defmodule Cambiatus.Workers.ClaimEmailWorker do
  @moduledoc """
  Worker that send emails when a claim is made.
  """

  use Oban.Worker,
    queue: :claim_email,
    max_attempts: 3,
    tags: ["claim"],
    unique: [period: 120]

  def perform(%Oban.Job{args: %{"claim_id" => claim_id}}) do
    case(Cambiatus.Objectives.get_claim(claim_id)) do
      {:ok, claim} ->
        CambiatusWeb.Email.claim(claim)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
