defmodule CambiatusWeb.Schema.Middleware.EmailSpecialAuthenticate do
  @moduledoc """
  Absinthe Middleware implementation that checks for the current user and automatically gives an error in case its not found
  """

  @behaviour Absinthe.Middleware

  def call(resolution, _) do
    case resolution.context do
      %{current_user: _} ->
        resolution

      %{user_unsub_email: _} ->
        resolution

      _ ->
        resolution
        |> Absinthe.Resolution.put_result(
          {:error, "Please sign in firt or use a valid unsubscription link"}
        )
    end
  end
end
