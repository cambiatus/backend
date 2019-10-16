defmodule BeSpiralWeb.Schema.Resolvers.ChatTest do
  @moduledoc """
  This module integration tests to for resolvers that work with the chat context
  """
  use BeSpiral.ApiCase

  describe "Chat Resolver" do
    test "get all preferences from a given user", %{conn: conn} do
      variables = %{
        "input" => %{
          "userId" => "user_id",
          "token" => "success"
        }
      }

      query = """
      query($input: ChatInput!) {
        chatPreferences(input: $input) {
          userId
          language
        }
      }
      """

      expected = %{
        "data" => %{
          "chatPreferences" => %{
            "language" => "en-US",
            "userId" => "user_id"
          }
        }
      }

      response =
        conn
        |> get("/api/graph", query: query, variables: variables)
        |> json_response(200)

      assert response == expected
    end

    test "update user's chat language", %{conn: conn} do
      language = "pt-BR"

      variables = %{
        "input" => %{
          "userId" => "user_id",
          "language" => language
        }
      }

      query = """
      mutation($input: ChatUpdateInput!) {
        updateChatLanguage(input: $input) {
          userId
          language
        }
      }
      """

      expected = %{
        "data" => %{
          "updateChatLanguage" => %{
            "language" => language,
            "userId" => "user_id"
          }
        }
      }

      response =
        conn
        |> post("/api/graph", query: query, variables: variables)
        |> json_response(200)

      assert response == expected
    end
  end
end
