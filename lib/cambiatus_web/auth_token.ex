defmodule CambiatusWeb.AuthToken do
  @moduledoc false

  alias CambiatusWeb.Endpoint

  @doc "Encodes given `user` and signs it, returning a token clients can use as ID"
  def sign(user, authorization \\ "user") do
    salt =
      case authorization do
        "user" ->
          auth_salt_user()

        "email" ->
          auth_salt_email()
      end

    Phoenix.Token.sign(Endpoint, salt, %{id: user.account})
  end

  @doc "Decodes original data from given `token` and verifies its integrity"
  def verify(token, authorization \\ "user") do
    salt =
      case authorization do
        "user" ->
          auth_salt_user()

        "email" ->
          auth_salt_email()
      end

    Phoenix.Token.verify(Endpoint, salt, token, max_age: 365 * 24 * 3_600)
  end

  def auth_salt_user() do
    Application.get_env(:cambiatus, :auth_salt)
  end

  def auth_salt_email() do
    Application.get_env(:cambiatus, :auth_salt_email)
  end
end
