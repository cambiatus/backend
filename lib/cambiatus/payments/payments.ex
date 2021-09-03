defmodule Cambiatus.Payments do
  @moduledoc """
  Context for all payments processing stuff on Cambiatus
  """

  alias Cambiatus.Repo
  alias Cambiatus.Payments.{Contribution, PaymentCallback}
  alias Cambiatus.Workers.ContributionPaypalWorker

  def list_contributions do
    {:ok, Repo.all(Contribution)}
  end

  def get_contribution(id) do
    case Repo.get(Contribution, id) do
      nil ->
        {:error, "No contribution with id: #{id} found"}

      found_contribution ->
        {:ok, found_contribution}
    end
  end

  def create_contribution(attrs \\ %{}) do
    %Contribution{}
    |> Contribution.changeset(attrs)
    |> Repo.insert()
  end

  def update_contribution(%Contribution{} = contribution, attrs) do
    contribution
    |> Contribution.changeset(attrs)
    |> Repo.update()
  end

  def create_payment_callback(attrs \\ %{}) do
    %PaymentCallback{}
    |> PaymentCallback.changeset(attrs)
    |> Repo.insert()
  end

  def schedule_payment_callback_worker(attrs \\ %{}) do
    %{body: attrs}
    |> ContributionPaypalWorker.new()
    |> Oban.insert()
  end
end
