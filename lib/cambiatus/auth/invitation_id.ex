defmodule Cambiatus.Auth.InvitationId do
  @moduledoc """
  Used to encode IDs so they can be shared in public. Uses a custom salt
  """
  defp salt do
    Application.get_env(:cambiatus, __MODULE__, []) |> Keyword.get(:salt, "default-salt")
  end

  defp coder do
    Hashids.new(salt: salt(), min_len: 6)
  end

  def encode(id) do
    Hashids.encode(coder(), id)
  end

  def decode(""), do: {:ok, 0}

  def decode(data) do
    case Hashids.decode(coder(), data) do
      {:ok, [val]} ->
        {:ok, val}

      _ ->
        {:error, "Something went wrong while decoding the hashid"}
    end
  end
end
