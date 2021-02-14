defmodule CambiatusWeb.AuthToken do
  @moduledoc false

  alias CambiatusWeb.Endpoint

  @auth_salt Application.get_env(:cambiatus, :auth_salt)

  @doc "Encodes given `user` and signs it, returning a token clients can use as ID"
  def sign(user) do
    Phoenix.Token.sign(Endpoint, @auth_salt, %{id: user.account})
  end

  @doc "Decodes original data from given `token` and verifies its integrity"
  def verify(token) do
    Phoenix.Token.verify(Endpoint, @auth_salt, token, max_age: 365 * 24 * 3_600)
  end
end
