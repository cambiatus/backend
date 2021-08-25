defmodule Cambiatus.Payments do
  @moduledoc """
  Context for all payments processing stuff on Cambiatus
  """

  alias Cambiatus.Repo
  alias Cambiatus.Payments.Contribution

  def list_contributions do
    {:ok, Repo.all(Contribution)}
  end

  def create_contribution(attrs \\ %{}) do
    %Contribution{}
    |> Contribution.changeset(attrs)
    |> Repo.insert()
  end
end
