defmodule CambiatusWeb.Schema.Middleware.Authenticate do
  @moduledoc """
  Absinthe Middleware implementation that checks for the current user and automatically gives an error in case its not found
  """

  @behaviour Absinthe.Middleware

  def call(resolution, _) do
    case resolution.context do
      %{current_user: _} ->
        resolution

      _ ->
        resolution
        |> Absinthe.Resolution.put_result({:error, "Please sign in first!"})
    end
  end
end
