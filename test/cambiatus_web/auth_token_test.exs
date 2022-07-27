defmodule CambiatusWeb.AuthTokenTest do
  use Cambiatus.DataCase
  use CambiatusWeb.ConnCase

  alias CambiatusWeb.AuthToken

  setup do
    {:ok, user: insert(:user)}
  end

  describe "Regular token authorization" do
    test "authorize token", %{user: user} do
      token = AuthToken.sign(user)

      assert {:ok, %{id: _}} = AuthToken.verify(token)
    end

    test "regular token is authorized for email use", %{user: user} do
      token = AuthToken.sign(user)

      assert {:error, :invalid} = AuthToken.verify(token, "email")
    end

    test "test regular token expration", %{user: user} do
      week_ago = System.system_time(:second) - 7 * 24 * 3_600

      two_weeks_ago = System.system_time(:second) - 14 * 24 * 3600

      week_old_token =
        Phoenix.Token.sign(
          CambiatusWeb.Endpoint,
          AuthToken.auth_salt("user"),
          %{
            id: user.account
          },
          signed_at: week_ago
        )

      two_weeks_old_token =
        Phoenix.Token.sign(
          CambiatusWeb.Endpoint,
          AuthToken.auth_salt("user"),
          %{
            id: user.account
          },
          signed_at: two_weeks_ago
        )

      assert {:ok, %{id: _}} = AuthToken.verify(week_old_token)
      assert {:error, :expired} = AuthToken.verify(two_weeks_old_token)
    end
  end

  describe "Email token authorization" do
    test "authorize email unsubscription token", %{user: user} do
      token = AuthToken.sign(user, "email")

      assert {:ok, %{id: _}} = AuthToken.verify(token, "email")
    end

    test "email token is not authorized for regular use", %{user: user} do
      token = AuthToken.sign(user, "email")

      assert {:error, :invalid} = AuthToken.verify(token)
    end

    test "test email token expration", %{user: user} do
      week_ago = System.system_time(:second) - 7 * 24 * 3_600

      two_weeks_ago = System.system_time(:second) - 14 * 24 * 3600

      week_old_token =
        Phoenix.Token.sign(
          CambiatusWeb.Endpoint,
          AuthToken.auth_salt("email"),
          %{
            id: user.account
          },
          signed_at: week_ago
        )

      two_weeks_old_token =
        Phoenix.Token.sign(
          CambiatusWeb.Endpoint,
          AuthToken.auth_salt("email"),
          %{
            id: user.account
          },
          signed_at: two_weeks_ago
        )

      assert {:ok, %{id: _}} = AuthToken.verify(week_old_token, "email")
      assert {:error, :expired} = AuthToken.verify(two_weeks_old_token, "email")
    end
  end
end
