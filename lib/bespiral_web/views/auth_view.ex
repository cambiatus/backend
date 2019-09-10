defmodule BeSpiralWeb.AuthView do
  use BeSpiralWeb, :view

  alias BeSpiral.Accounts.User
  alias BeSpiralWeb.AuthView

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

  def render("chat_error.json", %{error: error}) do
    case error do
      {:error, :chat_signin_bad_request} ->
        %{
          errors: %{
            details: "Chat error during sign in. Looks like data aren't in the correct format"
          }
        }

      {:error, :chat_signin_unauthorized} ->
        %{errors: %{details: "Chat error during sign in. Are the credentials right?"}}

      {:error, :chat_signin_unknown_error} ->
        %{errors: %{details: "Chat error during sign in. Unknown error :("}}

      {:error, :chat_signup_bad_request} ->
        %{
          errors: %{
            details: "Chat error during sign up. Looks like data aren't in the correct format"
          }
        }

      {:error, :chat_signup_unauthorized} ->
        %{errors: %{details: "Chat error during sign in. Are the credentials right?"}}

      {:error, :chat_signup_unknown_error} ->
        %{errors: %{details: "Chat error during sign up. Unknown error :("}}

      {:error, _} ->
        %{errors: %{details: "Chat unknown error :("}}
    end
  end
end
