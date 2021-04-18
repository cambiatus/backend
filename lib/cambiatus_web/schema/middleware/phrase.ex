defmodule CambiatusWeb.Schema.Middleware.Phrase do
  @moduledoc """
  Absinthe Middleware implementation that checks for the current user and automatically gives an error in case its not found
  """

  @behaviour Absinthe.Middleware

  def call(resolution, _) do
    resolution.value
    |> case do
      phrase when not is_nil(phrase) ->
        Map.update!(resolution, :context, &Map.put(&1, :phrase, phrase))
      _ ->
        resolution
    end
  end
end
