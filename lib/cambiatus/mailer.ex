defmodule Cambiatus.Mailer do
  @moduledoc "Module responsible for mailing helpers"

  use Bamboo.Mailer, otp_app: :cambiatus

  def sender do
    :cambiatus
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:sender_email)
  end
end
