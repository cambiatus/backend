defmodule CambiatusWeb.UserSocket do
  use Phoenix.Socket
  use Absinthe.Phoenix.Socket, schema: CambiatusWeb.Schema

  alias CambiatusWeb.AuthToken

  ## Channels
  # channel "room:*", EatYourDayWeb.RoomChannel

  # Socket params are passed from the client and can
  # be used to verify and authenticate a user. After
  # verification, you can put default assigns into
  # the socket that will be set for all channels, ie
  #
  #     {:ok, assign(socket, :user_id, verified_user_id)}
  #
  # To deny connection, return `:error`.
  #
  # See `Phoenix.Token` documentation for examples in
  # performing token verification on connect.

  def connect(params, socket, _) do
    context = build_context(params)
    socket = Absinthe.Phoenix.Socket.put_options(socket, context: context)

    {:ok, socket}
  end

  defp build_context(%{"Authorization" => "Bearer " <> token}) do
    with {:ok, %{id: account}} <- AuthToken.verify(token),
         %{} = user <- Cambiatus.Accounts.get_user(account) do
      %{current_user: user}
    else
      _ -> %{}
    end
  end

  defp build_context(_) do
    %{}
  end

  # Socket id's are topics that allow you to identify all sockets for a given user:
  #
  #     def id(socket), do: "user_socket:#{socket.assigns.user_id}"
  #
  # Would allow you to broadcast a "disconnect" event and terminate
  # all active sockets and channels for a given user:
  #
  #     EatYourDayWeb.Endpoint.broadcast("user_socket:#{user.id}", "disconnect", %{})
  #
  # Returning `nil` makes this socket anonymous.
  def id(_socket), do: nil
end
