ExUnit.start(timeout: 5 * 60_000, exclude: [:skip], capture_log: true)

# Set the pool mode to manual for explicitly checkouts
Ecto.Adapters.SQL.Sandbox.mode(Cambiatus.Repo, :manual)

# ensure ex_machina is started when running tests
{:ok, _} = Application.ensure_all_started(:ex_machina)
