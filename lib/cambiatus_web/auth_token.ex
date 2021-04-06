defmodule CambiatusWeb.AuthToken do
  @moduledoc false

  alias CambiatusWeb.Endpoint

  def gen_token(data) do
    Phoenix.Token.sign(Endpoint, auth_salt(), data)
  end

  @doc "Encodes given `user` and signs it, returning a token clients can use as ID"
  def sign(user) do
    Phoenix.Token.sign(Endpoint, auth_salt(), %{id: user.account})
  end

  @doc "Decodes original data from given `token` and verifies its integrity"
  def verify(token, max_age \\ 365 * 24 * 3_600)

  def verify(token, max_age) do
    Phoenix.Token.verify(Endpoint, auth_salt(), token, max_age: max_age)
  end

  def auth_salt() do
    Application.get_env(:cambiatus, :auth_salt)
  end

  defp encrypt(endpoint, secret, data) do
    endpoint.config(:secret_key_base)
    |> Plug.Crypto.encrypt(secret, data)
  end

  defp decrypt(endpoint, secret, token) do
    endpoint.config(:secret_key_base)
    |> Plug.Crypto.decrypt(secret, token)
  end
end
