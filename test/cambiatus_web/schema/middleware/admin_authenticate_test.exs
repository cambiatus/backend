defmodule CambiatusWeb.Schema.Middleware.AdminAuthenticateTest do
  use Cambiatus.DataCase

  alias CambiatusWeb.Schema.Middleware.AdminAuthenticate

  describe "call/2" do
    setup do
      admin = insert(:user)
      community = insert(:community, creator: admin.account)

      %{admin: admin, community: community}
    end

    test "Admin user, no error", %{admin: admin, community: community} do
      resolution = %Absinthe.Resolution{
        context: %{current_user: admin, current_community: community}
      }

      resolution = AdminAuthenticate.call(resolution, nil)

      assert resolution.errors == []
    end

    test "Regular user, error", %{community: community} do
      another_user = insert(:user)

      resolution = %Absinthe.Resolution{
        context: %{current_user: another_user, current_community: community}
      }

      resolution = AdminAuthenticate.call(resolution, nil)

      assert resolution.errors == ["Logged user isn't an admin"]
    end
  end
end
