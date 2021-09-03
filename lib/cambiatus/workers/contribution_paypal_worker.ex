defmodule Cambiatus.Workers.ContributionPaypalWorker do
  @moduledoc """
  Worker that process contributions made through Paypal.
  """

  use Oban.Worker,
    queue: :contribution_paypal,
    max_attempts: 3,
    tags: ["contribution"]

  # unique: [period: 120]

  alias Cambiatus.Payments
  alias Cambiatus.Payments.PaymentCallback

  @impl Oban.Worker
  @spec perform(Oban.Job.t()) :: :ok | {:error, <<_::168>>}
  def perform(%Oban.Job{args: %{"body" => attrs} = _args}) do
    case attrs do
      %{"resource" => %{"invoice_id" => contribution_id}} ->
        {:ok, contribution} = Payments.get_contribution(contribution_id)

        payment_callback = PaymentCallback.changeset(%PaymentCallback{}, attrs)

        r =
          contribution
          |> Payments.update_contribution(%{contribution_payment_callbacks: payment_callback})

        IO.inspect(r)

        :ok

      _ ->
        {:error, "Can't find invoice_id"}
    end

    # {:ok, result} =
    #   %PaymentCallback{}
    #   |> PaymentCallback.changeset(attrs)
    #   |> Repo.insert()

    # contribution_id
    # |> Payments.get_contribution()
    # |> case do
    #   {:error, _} = error ->
    #     error

    #   {:ok, contribution} ->
    #     IO.inspect(contribution)

    #     :ok
    # end
  end

  # process body
  # Find related contribution
  # associate and insert data
end
