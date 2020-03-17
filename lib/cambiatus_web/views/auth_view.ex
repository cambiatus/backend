defmodule CambiatusWeb.AuthView do
  use CambiatusWeb, :view

  alias Cambiatus.Accounts.User
  alias CambiatusWeb.AuthView

  def render("show.json", %{user: user}) do
    %{data: render_one(user, AuthView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{id: user.account}
  end

  def render("auth.json", %{user: %User{} = user}) do
    %{
      data: %{
        user: %{
          account: user.account,
          name: user.name,
          avatar: user.avatar,
          email: user.email,
          bio: user.bio,
          interests: user.interests,
          location: user.location,
          chat_user_id: user.chat_user_id,
          chat_token: user.chat_token,
          communities: Enum.map(user.communities, &Map.get(&1, :symbol))
        }
      }
    }
  end

  def render("unauthorized.json", _) do
    %{errors: %{details: "User already registered. Please try signing in instead."}}
  end
end
