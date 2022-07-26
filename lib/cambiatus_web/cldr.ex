defmodule CambiatusWeb.Cldr do
  @moduledoc """
  This module is responsible for setting up the ex_cldr library
  """

  use Cldr,
    default_locale: "en",
    locales: ["am", "en", "es-ES", "pt-BR"],
    gettext: CambiatusWeb.Gettext,
    data_dir: "./priv/cldr",
    otp_app: :cambiatus,
    providers: [Cldr.DateTime, Cldr.Number, Cldr.Calendar]

  def put_gettext_locale(gettext_locale) do
    locale = locale_aliases(gettext_locale)
    Cldr.put_locale(CambiatusWeb.Cldr, locale)
  end

  # These alises convert between format used by the gettext library (stored in db)
  # and the format used by the ex_cldr library
  defp locale_aliases("amh-ETH"), do: "am"
  defp locale_aliases("en-US"), do: "en"
  defp locale_aliases("es-ES"), do: "es-ES"
  defp locale_aliases("pt-BR"), do: "pt-BR"
end
