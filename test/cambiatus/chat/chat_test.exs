defmodule Cambiatus.ChatTest do
  use Cambiatus.DataCase

  alias Cambiatus.Accounts.User
  alias Cambiatus.Chat

  describe "Sign in flow:" do
    setup :valid_community_and_user

    test "sign in successfully when valid params", %{user_chat_success: user} do
      response =
        User
        |> struct(user)
        |> Chat.sign_in()

      assert {:ok, u} = response
      assert u.chat_user_id == user.user_id
    end

    test "sign in fails when bad request", %{user_chat_bad_request: user} do
      response =
        User
        |> struct(user)
        |> Chat.sign_in()

      assert {:error, :chat_signin_bad_request} == response
    end

    test "sign in fails when unauthorized", %{user_chat_unauthorized: user} do
      response =
        User
        |> struct(user)
        |> Chat.sign_in()

      assert {:error, :chat_signin_unauthorized} == response
    end

    test "sign in fails when unknown error", %{user_chat_unknown: user} do
      response =
        User
        |> struct(user)
        |> Chat.sign_in()

      assert {:error, :chat_signin_unknown_error} == response
    end
  end

  describe "Sign up flow:" do
    setup :valid_community_and_user

    test "sign up successfully when valid params", %{user_chat_success: user} do
      response =
        User
        |> struct(user)
        |> Chat.sign_up()

      assert {:ok, u} = response
      assert u.account == user.account
    end

    test "sign up fails when bad request", %{user_chat_bad_request: user} do
      response =
        User
        |> struct(user)
        |> Chat.sign_up()

      assert {:error, :chat_signup_bad_request} == response
    end

    test "sign up fails when unauthorized", %{user_chat_unauthorized: user} do
      response =
        User
        |> struct(user)
        |> Chat.sign_up()

      assert {:error, :chat_signup_unauthorized} == response
    end

    test "sign up fails when unknown error", %{user_chat_unknown: user} do
      response =
        User
        |> struct(user)
        |> Chat.sign_up()

      assert {:error, :chat_signup_unknown_error} == response
    end
  end

  describe "Get preferences flow:" do
    setup :valid_community_and_user

    test "get preferences successfully when valid params", %{user_chat_success: user} do
      response = Chat.get_preferences(user)

      assert {:ok, %{user_id: user.user_id, language: "en-US"}} == response
    end

    test "get preferences fails when bad request", %{user_chat_bad_request: user} do
      response = Chat.get_preferences(user)

      assert {:ok, %{user_id: user.user_id, language: ""}} == response
    end

    test "get preferences fails when unauthorized", %{user_chat_unauthorized: user} do
      response = Chat.get_preferences(user)

      assert {:error, :unauthorized} == response
    end

    test "get preferences fails when unknown error", %{user_chat_unknown: user} do
      response = Chat.get_preferences(user)

      assert {:error, :unknown_error} == response
    end
  end

  describe "Update language flow:" do
    setup :valid_community_and_user

    test "update language successfully when valid params", %{user_chat_success: user} do
      response = Chat.update_language(user)

      assert {:ok, %{user_id: user.user_id, language: user.language}} == response
    end

    test "update language fails when bad request", %{user_chat_bad_request: user} do
      response = Chat.update_language(user)

      assert {:error, :bad_request} == response
    end

    test "update language fails when unauthorized", %{user_chat_unauthorized: user} do
      response = Chat.update_language(user)

      assert {:error, :unauthorized} == response
    end

    test "update language fails with invalid user", %{user_chat_unknown: user} do
      response = Chat.update_language(user)

      assert {:error, :unknown_error} == response
    end
  end
end
