defmodule Cambiatus.Social do
  @moduledoc """
    The Social context. Handles everything related to news.
  """

  alias Cambiatus.Repo
  alias Cambiatus.Social.News

  @spec data :: Dataloader.Ecto.t()
  def data(params \\ %{}), do: Dataloader.Ecto.new(Repo, query: &query/2, default_params: params)

  def query(queryable, _params) do
    queryable
  end

  def create_news(attrs \\ %{}) do
    %News{}
    |> News.changeset(attrs)
    |> Repo.insert()
  end
end
