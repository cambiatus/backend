defmodule BeSpiralWeb.ErrorView do
  use BeSpiralWeb, :view

  def render("500.json", assigns) do
    message =
      case assigns do
        %{reason: %{message: message}} ->
          message

        %{reason: message} when is_binary(message) ->
          message

        _ ->
          "Internal Server Error"
      end

    %{errors: %{detail: message}}
  end

  def render("400.json", assigns) do
    message =
      case assigns do
        %{reason: %{message: message}} -> message
        %{reason: message} when is_binary(message) -> message
        _ -> "Bad Request"
      end

    %{errors: %{detail: message}}
  end

  def render("404.json", _assigns) do
    %{errors: %{detail: "Not Found"}}
  end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
