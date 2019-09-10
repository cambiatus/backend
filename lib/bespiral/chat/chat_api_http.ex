defmodule BeSpiral.Chat.ApiHttp do
  @moduledoc "Chat API Manager"

  import BeSpiral.Chat.Api

  use Tesla, only: [:post, :get], docs: false

  plug(Tesla.Middleware.BaseUrl, chat_base_url())
  plug(Tesla.Middleware.JSON)
  plug(Tesla.Middleware.Logger)

  @behaviour BeSpiral.Chat.Api

  @impl BeSpiral.Chat.Api
  def login(%{username: _, password: _} = body) do
    chat_login_endpoint()
    |> post(body)
    |> parse_response
  end

  @impl BeSpiral.Chat.Api
  def register(%{username: _, email: _, password: _, name: _} = user) do
    body =
      user
      |> Map.put(:roles, [chat_user_role()])
      |> Map.put(:joinDefaultChannels, false)

    headers = auth_headers(chat_user_id(), chat_token())

    chat_register_endpoint()
    |> post(body, headers: headers)
    |> parse_response
  end

  @impl BeSpiral.Chat.Api
  def get_preferences(%{user_id: user_id, token: token}) do
    headers = auth_headers(user_id, token)

    chat_get_preferences_endpoint()
    |> get(headers: headers)
    |> parse_response
  end

  @impl BeSpiral.Chat.Api
  def update_language(%{user_id: user_id, language: language}) do
    case user_id do
      "" ->
        {:error, :bad_request}

      _ ->
        body = %{
          "userId" => user_id,
          "data" => %{
            "language" => language
          }
        }

        headers = auth_headers(chat_user_id(), chat_token())

        chat_set_preferences_endpoint()
        |> post(body, headers: headers)
        |> parse_response
    end
  end

  defp auth_headers(user_id, token) do
    [
      {"Content-Type", "application/json"},
      {"X-User-Id", user_id},
      {"X-Auth-Token", token}
    ]
  end

  defp parse_response(response) do
    case response do
      {:ok, %Tesla.Env{body: body, status: 200}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: 400}} ->
        {:error, :bad_request}

      {:ok, %Tesla.Env{status: 401}} ->
        {:error, :unauthorized}

      _ ->
        {:error, :unknown_error}
    end
  end

  defp chat_base_url do
    :bespiral
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:chat_base_url)
  end

  defp chat_register_endpoint, do: "/api/v1/users.create"

  defp chat_login_endpoint, do: "/api/v1/login"

  defp chat_get_preferences_endpoint, do: "/api/v1/users.getPreferences"

  defp chat_set_preferences_endpoint, do: "/api/v1/users.setPreferences"

  defp chat_token do
    :bespiral
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:chat_token)
  end

  defp chat_user_id do
    :bespiral
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:chat_user_id)
  end

  defp chat_user_role do
    :bespiral
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:chat_user_role)
  end
end
