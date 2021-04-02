defmodule Cambiatus.Auth.Phrase do
  @moduledoc """
  Generate random auth phrase
  """
  use Puid, bits: 128, charset: :alphanum
end
