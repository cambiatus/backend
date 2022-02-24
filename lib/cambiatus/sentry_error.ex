defmodule Cambiatus.SentryError do
  def run(blueprint, _) do
    errors = blueprint.result.errors
    Sentry.Context.set_extra_context(%{errors: errors})

    {:ok, blueprint}
  end
end
