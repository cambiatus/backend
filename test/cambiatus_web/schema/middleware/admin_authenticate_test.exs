defmodule CambiatusWeb.Schema.Middleware.AdminAuthenticateTest do
  use Cambiatus.DataCase

  alias CambiatusWeb.Schema.Middleware.AdminAuthenticate

  describe "call/2" do
    setup do
      domain_name = "test.cambiatus.io"
      admin = insert(:user)
      insert(:community, creator: admin.account, subdomain: %{name: domain_name})

      %{admin: admin, domain_name: domain_name}
    end

    test "Admin user, no error", %{admin: admin, domain_name: domain_name} do
      resolution = %Absinthe.Resolution{
        context: %{current_user: admin, domain: domain_name}
      }

      resolution = AdminAuthenticate.call(resolution, nil)

      assert resolution.errors == []
    end

    test "Regular user, error", %{domain_name: domain_name} do
      another_user = insert(:user)

      resolution = %Absinthe.Resolution{
        context: %{current_user: another_user, domain: domain_name}
      }

      resolution = AdminAuthenticate.call(resolution, nil)

      assert resolution.errors == ["Logged user isn't an admin"]
    end
  end
end
