defmodule Cambiatus.Social do
  @moduledoc """

  """

  alias Cambiatus.Repo

  @spec data :: Dataloader.Ecto.t()
  def data(params \\ %{}), do: Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)

  def query(queryable, _params) do
    queryable
  end
end
