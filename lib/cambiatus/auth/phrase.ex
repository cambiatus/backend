defmodule Cambiatus.Auth.Phrase do
  use Puid, bits: 128, charset: :alphanum
end
