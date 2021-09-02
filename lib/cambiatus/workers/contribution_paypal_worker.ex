defmodule Cambiatus.Workers.ContributionPaypalWorker do
  @moduledoc """
  Worker that process contributions made through Paypal.
  """

  use Oban.Worker, queue: :contribution_paypal, max_attempts: 3

  alias Cambiatus.Payments

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"contribution_id" => contribution_id} = _args}) do
    contribution_id
    |> Payments.get_contribution()
    |> case do
      {:error, _} = error ->
        error

      {:ok, contribution} ->
        IO.inspect(contribution)

        :ok
    end
  end
end
