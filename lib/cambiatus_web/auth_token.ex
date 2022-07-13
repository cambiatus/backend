defmodule CambiatusWeb.AuthToken do
  @moduledoc false

  alias CambiatusWeb.Endpoint

  @doc "Encodes given `user` and signs it, returning a token clients can use as ID"
  def sign(user, authorization \\ "user") do
    Phoenix.Token.sign(Endpoint, auth_salt(authorization), %{id: user.account})
  end

  @doc "Decodes original data from given `token` and verifies its integrity"
  def verify(token, authorization \\ "user") do
    Phoenix.Token.verify(Endpoint, auth_salt(authorization), token, max_age: 365 * 24 * 3_600)
  end

  def auth_salt("user"), do: Application.get_env(:cambiatus, :auth_salt)

  def auth_salt("email"), do: Application.get_env(:cambiatus, :auth_salt_email)
end
