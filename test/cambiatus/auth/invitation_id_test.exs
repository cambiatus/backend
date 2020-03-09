defmodule Cambiatus.Auth.InvitationIdTest do
  use Cambiatus.DataCase

  alias Cambiatus.Auth.InvitationId

  describe("Hashid usage on invitation") do
    test "Successfully encodes and decodes a string" do
      number = 1
      assert InvitationId.decode(InvitationId.encode(number)) == {:ok, number}
    end
  end
end
