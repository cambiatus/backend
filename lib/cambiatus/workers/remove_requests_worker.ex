defmodule Cambiatus.Workers.RemoveRequestsWorker do
  @moduledoc """
  Worker that removes old requests from table
  """

  use Oban.Worker

  alias Cambiatus.Auth

  def perform(_) do
    Auth.delete_expired_requests()

    :ok
  end
end
