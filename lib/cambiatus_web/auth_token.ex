defmodule CambiatusWeb.AuthToken do
  @moduledoc false

  alias CambiatusWeb.Endpoint
  alias Phoenix.Token

  @user_salt "user auth salt"
  # TODO: Create Salt on config

  @doc "Encodes given `user` and signs it, returning a token clients can use as ID"
  def sign(user) do
    Token.sign(Endpoint, @user_salt, %{id: user.account})
  end

  @doc "Decodes original data from given `token` and verifies its integrity"
  def verify(token) do
    Token.verify(Endpoint, @user_salt, token, max_age: 365 * 24 * 3_600)
  end
end
