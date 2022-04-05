defmodule Cambiatus.SentryError do
  @moduledoc false

  def run(blueprint, _) do
    errors = blueprint.result.errors
    Sentry.Context.set_extra_context(%{errors: errors})

    {:ok, blueprint}
  end
end
