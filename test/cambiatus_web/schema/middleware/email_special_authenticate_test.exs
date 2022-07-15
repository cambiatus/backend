defmodule CambiatusWeb.Schema.Middleware.EmailSpecialAuthenticateTest do
  use Cambiatus.DataCase

  alias CambiatusWeb.Schema.Middleware.{EmailSpecialAuthenticate, Authenticate}

  describe "call/2" do
    setup do
      user = insert(:user)

      %{user: user}
    end

    test "accept email unsub permission", %{user: user} do
      resolution = %Absinthe.Resolution{context: %{user_unsub_email: user}}

      resolution = EmailSpecialAuthenticate.call(resolution, nil)

      assert resolution.errors == []
    end

    test "accept regular permission", %{user: user} do
      resolution = %Absinthe.Resolution{context: %{current_user: user}}

      resolution = EmailSpecialAuthenticate.call(resolution, nil)

      assert resolution.errors == []
    end

    test "regular authentication middleware doesn't accept email unsub permission", %{user: user} do
      resolution = %Absinthe.Resolution{context: %{user_unsub_email: user}}

      resolution = Authenticate.call(resolution, nil)

      assert resolution.errors == ["Please sign in first!"]
    end

    test "admin authentication middleware doesn't accept email unsub permission", %{user: user} do
      community = insert(:community, creator: user.account)

      resolution = %Absinthe.Resolution{
        context: %{user_unsub_email: user, current_community: community}
      }

      resolution = Authenticate.call(resolution, nil)

      assert resolution.errors == ["Please sign in first!"]
    end
  end
end
