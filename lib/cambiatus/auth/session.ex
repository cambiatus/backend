defmodule Cambiatus.Auth.Session do
  @moduledoc "Cambiatus Account Authentication and Signup Manager"

  @valid_token 2 * 24 * 3600

  import Ecto.Query

  alias CambiatusWeb.AuthToken
  alias Cambiatus.Auth.UserToken
  alias Cambiatus.{
    Accounts,
    Repo,
    Auth.Ecdsa,
    Auth.Phrase
  }

  def create_phrase(user, user_agent) do
    phrase = Phrase.generate()

    %UserToken{}
    |> UserToken.changeset(%{phrase: phrase, context: "auth", user_agent: user_agent}, user)
    |> Repo.insert()
    |> case do
      {:ok, _} -> {:ok, phrase}
      {:error, _err} -> {:error, "Phrase exists already"}
    end
  end

  def verify_session_token(token) do
    %{token: token, filter: :session}
    |> get_user_token()
    |> case do
      user_token when is_map(user_token) ->
        {AuthToken.verify(user_token.token, @valid_token), user_token}

      nil ->
        {:error, "Session not found"}
    end
  end

   def verify_session_token(account, token) do
    %{account: account, filter: :session}
    |> get_user_token()
    |> Map.values()
    |> Enum.member?(token)
    |> case do
      true ->
        AuthToken.verify(token, @valid_token)

      false ->
        delete_user_token(%{account: account, filter: :auth})
        {:error, "Session not found"}
    end
  end

  def get_account_from_token({{:ok, _}, user_token}) do
    Cambiatus.Accounts.get_user(user_token.user_id)
  end

  def get_account_from_token({{:error, _}, _}) do
    {:error, "Invalid session"}
  end

  def get_account_from_token({:error, _}) do
    {:error, "Invalid session"}
  end

  def verify_signature_helper(nil, _phrase, _signature) do
    {:error, "No phrase found"}
  end
  def verify_signature_helper(%{user_id: account}, phrase, signature, user_agent) do
    if Ecdsa.verify_signature(account, signature, phrase) do
      user = Accounts.get_user(account)
      token = create_session(user, user_agent)
      delete_user_token(%{account: account, filter: :auth})

      {:ok, {user, token}}
    else
      {:error, "Invalid signature"}
    end
  end

  def create_session({:error, _} = err), do: err

  def create_session(user, user_agent) do
    token = AuthToken.gen_token(%{account: user.account, user_agent: user_agent})

    %UserToken{}
    |> UserToken.changeset(%{token: token, context: "session", user_agent: user_agent}, user)
    |> Repo.insert()
    |> case do
      {:ok, _} -> token
      {:error, _err} -> :error
    end
  end

  def get_user_token(%{account: account, filter: :session}) do
    from("user_tokens",
      where: [context: "session", user_id: ^account],
      select: [:context, :user_id, :token]
    )
    |> Repo.one()
  end

  def get_all_user_token(%{account: account, filter: :session}) do
    from("user_tokens",
      where: [context: "session", user_id: ^account],
      select: [:context, :user_id, :token]
    )
    |> Repo.all()
  end

  def get_user_token(%{token: token, filter: :session}) do
    from("user_tokens",
      where: [context: "session", token: ^token],
      select: [:context, :user_id, :token]
    )
    |> Repo.one()
  end

  def get_user_token(%{phrase: phrase, filter: :auth}) do
    from("user_tokens",
      where: [context: "auth", phrase: ^phrase],
      select: [:context, :user_id, :token, :phrase]
    )
    |> Repo.one()
  end

  def get_user_token(%{account: account, filter: :auth}) do
    from("user_tokens",
      where: [context: "auth", user_id: ^account],
      select: [:context, :user_id, :token, :phrase]
    )
    |> Repo.one()
  end

  def delete_user_token(%{token: token, filter: :session}) do
    from("user_tokens",
      where: [context: "session", token: ^token]
    )
    |> Repo.delete_all()
  end

  def delete_user_token(%{account: account, filter: :session}) do
    from("user_tokens",
      where: [context: "session", user_id: ^account]
    )
    |> Repo.delete_all()
  end

  def delete_user_token(%{account: account, filter: :auth}) do
    from("user_tokens",
      where: [context: "auth", user_id: ^account]
    )
    |> Repo.delete_all()
  end

  def delete_all_user_token() do
    [:session, :auth]
    |> Enum.each(&delete_all_user_token(&1))
  end

  def delete_all_user_token(:auth) do
    from("user_tokens",
      where: [context: "auth"]
    )
    |> Repo.delete_all()
  end

  def delete_all_user_token(:session) do
    from("user_tokens",
      where: [context: "session"]
    )
    |> Repo.delete_all()
  end
end
