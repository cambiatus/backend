defmodule Cambiatus.Workers.ContributionPaypalWorker do
  @moduledoc """
  Worker that process contributions made through Paypal.
  """

  use Oban.Worker,
    queue: :contribution_paypal,
    max_attempts: 3,
    tags: ["contribution"],
    unique: [period: 120]

  alias Cambiatus.{Payments, Repo}
  alias Cambiatus.Payments.{Contribution, PaymentCallback}

  def perform(%Oban.Job{args: %{"body" => attrs} = _args}) do
    case attrs do
      %{"resource" => %{"invoice_id" => contribution_id}} ->
        {:ok, contribution} = Payments.get_contribution(contribution_id)

        payment_callback = Payments.create_payment_callback(%{payload: attrs})

        contribution
        |> Repo.preload(:payment_callbacks)
        |> Ecto.Changeset.change()
        |> Ecto.Changeset.put_assoc(:payment_callbacks, [payment_callback])
        |> Repo.update()

      _ ->
        {:error, "Can't find invoice_id"}
    end
  end

  # process body
  # Find related contribution
  # associate and insert data
end
