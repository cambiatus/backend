defmodule Cambiatus.FileUploadTest do
  @moduledoc """
  Unit tests for the upload module
  """
  use Cambiatus.DataCase
  alias Cambiatus.FileUploader, as: Uploader

  # We use this header to fool the application into thinking we're giving it a GIF image.
  # Pretend it's this one https://i.imgur.com/0Y1xISa.gif
  @gif_header "GIF87a"
  @pdf_header "%PDF"

  describe "upload a file" do
    %{
      1 => :ok,
      1_000_000 => :ok,
      10_000_000 => :error
    }
    |> Enum.each(fn {input, exp} ->
      test "Uploading #{input / 1_000_000}MB should result in #{exp}" do
        result = Uploader.save(%File.Stat{size: unquote(input)}, "image/gif", @gif_header)

        assert {unquote(exp), _} = result
      end
    end)

    %{
      @gif_header => :ok,
      @pdf_header => :ok,
      "" => :error
    }
    |> Enum.each(fn {input, exp} ->
      test "The header #{input} should result in #{exp}" do
        result = Uploader.save(%File.Stat{size: 1_000_000}, "image/gif", unquote(input))

        assert {unquote(exp), _} = result
      end
    end)
  end
end
