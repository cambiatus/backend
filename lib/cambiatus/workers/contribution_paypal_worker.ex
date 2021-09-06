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
  alias Cambiatus.Payments.PaymentCallback
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
          |> Ecto.Changeset.change()
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

  # process body
  # Find related contribution
  # associate and insert data
end
