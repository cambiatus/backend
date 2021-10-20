defmodule Cambiatus.Payments do
  @moduledoc """
  Context for all payments processing stuff on Cambiatus
  """

  alias Cambiatus.Repo
  alias Cambiatus.Payments.{Contribution, PaymentCallback}
  alias Cambiatus.Workers.ContributionPaypalWorker

  @spec data(any) :: Dataloader.Ecto.t()
  def data(params \\ %{}) do
    Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)
  end

  def query(Contribution, filters) do
    query =
      filters
      |> Enum.reduce(Contribution, fn
        {:community_id, community_id}, query ->
          Contribution.from_community(query, community_id)

        {:status, status}, query ->
          Contribution.with_status(query, status)
      end)

    query
    |> Contribution.newer_first()
  end

  def query(queryable, _params), do: queryable

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

  def schedule_payment_callback_worker(payment_callback_id) do
    %{payment_callback_id: payment_callback_id}
    |> ContributionPaypalWorker.new()
    |> Oban.insert()
  end
end
