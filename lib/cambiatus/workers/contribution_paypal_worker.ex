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
  alias Ecto.Multi

  def perform(%Oban.Job{args: %{"payment_callback_id" => payment_callback_id}}) do
    payment_callback = Repo.get(PaymentCallback, payment_callback_id)

    payment_callback.payload
    |> case do
      %{"resource" => %{"invoice_id" => contribution_id}} = attrs ->
        {:ok, contribution} = Payments.get_contribution(contribution_id)
        contribution = Repo.preload(contribution, :payment_callbacks)

        Multi.new()
        |> Multi.run(:contribution, fn repo, _ ->
          contribution
          |> Repo.preload(:payment_callbacks)
          |> process_paypal(attrs)
          |> Ecto.Changeset.put_assoc(
            :payment_callbacks,
            [payment_callback] ++ contribution.payment_callbacks
          )
          |> repo.update()
        end)
        |> Multi.update(
          :set_processed,
          PaymentCallback.changeset(payment_callback, %{processed: true})
        )
        |> Repo.transaction()
        |> case do
          {:ok, _} ->
            :ok

          {:error, _, %{valid?: false}} ->
            {:error, :invalid_changeset}
        end

      _ ->
        {:error, "Can't find invoice_id"}
    end
  end

  def process_paypal(contribution, %{
        "event_type" => event_type,
        "resource" => %{"id" => external_id}
      }) do
    event_type
    |> case do
      "PAYMENT.CAPTURE.COMPLETED" ->
        :approved

      "PAYMENT.CAPTURE.DENIED" ->
        :rejected

      _ ->
        {:error, "can't process paypal event with id #{external_id}"}
    end
    |> case do
      {:error, _} ->
        Contribution.changeset(contribution, %{status: :paypal_error})

      new_status ->
        Contribution.changeset(contribution, %{status: new_status})
    end
  end
end
