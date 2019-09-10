defmodule BeSpiral.Mailer do
  @moduledoc "Module responsible for mailing helpers"

  use Bamboo.Mailer, otp_app: :bespiral

  def sender do
    :bespiral
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:sender_email)
  end
end
