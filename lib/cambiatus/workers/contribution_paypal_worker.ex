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

  def perform(%Oban.Job{args: %{"body" => attrs} = _args}) do
    case attrs do
      %{"resource" => %{"invoice_id" => contribution_id}} ->
        {:ok, contribution} = Payments.get_contribution(contribution_id)

        payment_callback_changeset =
          %PaymentCallback{}
          |> PaymentCallback.changeset(%{payload: attrs})

        Multi.new()
        |> Multi.insert(:payment_callback, payment_callback_changeset)
        |> Multi.run(:contribution, fn repo, %{payment_callback: payment_callback} ->
          contribution
          |> Repo.preload(:payment_callbacks)
          |> process_paypal(attrs)
          |> Ecto.Changeset.put_assoc(:payment_callbacks, [payment_callback])
          |> repo.update()
        end)
        |> Repo.transaction()
        |> case do
          {:ok, _} ->
            :ok

          {:error, _, %{valid?: false}} ->
            {:error, :changeset_invalid}
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
        {:error, "can't process paypal event"}
    end
    |> case do
      {:error, _} ->
        Contribution.changeset(contribution, %{status: :paypal_error})

      new_status ->
        Contribution.changeset(contribution, %{status: new_status, external_id: external_id})
    end
  end
end
