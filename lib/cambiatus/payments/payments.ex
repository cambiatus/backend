defmodule Cambiatus.Payments do
  @moduledoc """
  Context for all payments processing stuff on Cambiatus
  """

  alias Cambiatus.Repo
  alias Cambiatus.Payments.{Contribution, PaymentCallback}

  def list_contributions do
    {:ok, Repo.all(Contribution)}
  end

  def create_contribution(attrs \\ %{}) do
    %Contribution{}
    |> Contribution.changeset(attrs)
    |> Repo.insert()
  end

  def create_payment_callback(attrs \\ %{}) do
    %PaymentCallback{}
    |> PaymentCallback.changeset()
    |> Repo.insert()
  end
end
