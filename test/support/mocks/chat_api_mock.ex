defmodule Cambiatus.Chat.ApiMock do
  @moduledoc "Chat API Manager"

  import Cambiatus.Chat.Api

  @behaviour Cambiatus.Chat.Api

  @impl Cambiatus.Chat.Api
  def login(%{username: _, password: _pass} = body) do
    case body do
      %{username: "success", password: _} ->
        {:ok,
         %{"status" => "success", "data" => %{"userId" => "user_id", "authToken" => "token"}}}

      %{username: "bad_request", password: _} ->
        {:error, :bad_request}

      %{username: "unauthorized", password: _} ->
        {:error, :unauthorized}

      _ ->
        {:error, :unknown_error}
    end
  end

  @impl Cambiatus.Chat.Api
  def register(%{username: _, email: _, password: _, name: _} = user) do
    case user do
      %{username: "success", email: _, password: _, name: _} ->
        {:ok, %{"success" => true}}

      %{username: "bad_request", email: _, password: _, name: _} ->
        {:error, :bad_request}

      %{username: "unauthorized", email: _, password: _, name: _} ->
        {:error, :unauthorized}

      _ ->
        {:error, :unknown_error}
    end
  end

  @impl Cambiatus.Chat.Api
  def get_preferences(%{user_id: _, token: _} = header) do
    case header do
      %{user_id: "user_id", token: "success"} ->
        {:ok, %{"preferences" => %{"language" => "en-US"}, "success" => true}}

      %{user_id: "user_id", token: "bad_request"} ->
        {:error, :bad_request}

      %{user_id: "user_id", token: "unauthorized"} ->
        {:error, :unauthorized}

      _ ->
        {:error, :unknown_error}
    end
  end

  @impl Cambiatus.Chat.Api
  def update_language(%{user_id: _, language: _} = body) do
    case body do
      %{user_id: "user_id", language: "bad_request"} ->
        {:error, :bad_request}

      %{user_id: "user_id", language: "unauthorized"} ->
        {:error, :unauthorized}

      %{user_id: "user_id", language: language} ->
        {:ok,
         %{
           "success" => true,
           "user" => %{
             "_id" => "user_id",
             "settings" => %{"preferences" => %{"language" => language}}
           }
         }}

      _ ->
        {:error, :unknown_error}
    end
  end
end
