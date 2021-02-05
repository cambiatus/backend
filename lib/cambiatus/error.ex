defmodule Cambiatus.Error do
  @moduledoc """
  Standard error structure to be used in Cambiatus.

  Used to represent and display operation statuses in a more standard way

  Errors have two fields:
  * `type`: atom representing the possible error types
  * `message`: strings with the error message
  """
  require Logger

  alias Cambiatus.Error

  defstruct [:type, :message]

  @doc """
  Converts common error structures used on libraries such as Ecto, Absinthe to `Cambiatus.Error`
  """
  def from(%Ecto.Changeset{valid?: false} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {err, opts} ->
      Enum.reduce(opts, err, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  def from(other) do
    Logger.error("Unhandled error term: \n#{inspect(other)}")
    Sentry.capture_message("Unhandled error term:", extra: %{error: other})

    %Error{type: :unhandled_error, message: "Unhandled term"}
  end
end
