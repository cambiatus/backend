defmodule CambiatusWeb.UploadControllerTest do
  use Cambiatus.DataCase
  use CambiatusWeb.ConnCase

  require Poison

  @test_image_path Path.join(File.cwd!(), "/test/assets/")

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "*/*")}
  end

  describe "Uploads" do
    test "upload an image",
         %{conn: conn} do
      # Send a post request to upload the image "landscape.jpg" and check if 200 is returned

      filename = "landscape.jpg"

      upload = %Plug.Upload{
        path: Path.join(@test_image_path, filename),
        filename: filename,
        content_type: "image/jpeg"
      }

      reset_image(upload.path)

      conn = post(conn, "/api/upload", %{:file => upload})

      assert conn.status == 200
    end

    test "remove metada from an image",
         %{conn: conn} do
      # Send a post request to upload the image "portrait.jpg" and check if metadata
      # has been removed and only allowed metadata was kept

      filename = "portrait.jpg"

      upload = %Plug.Upload{
        path: Path.join(@test_image_path, filename),
        filename: filename,
        content_type: "image/jpeg"
      }

      # Get a list of metadata that is accepted on the final image

      basic_metadata = metadata_whitelist()

      # Resets metadata on the image to be tested

      reset_image(upload.path)

      # Get all the original metadata on the image and check if there's more metadata than
      # the amount allowed

      {metadata_input, 0} = System.cmd("exiftool", ["-j", upload.path])
      metadata_input = metadata_input |> Poison.decode!() |> List.first() |> Map.keys()

      assert Enum.count(basic_metadata) < Enum.count(metadata_input)

      conn = post(conn, "/api/upload", %{:file => upload})

      # After the image upload, check if only the allowed metadata are present in the output

      {metadata_output, 0} = System.cmd("exiftool", ["-j", upload.path])
      metadata_output = metadata_output |> Poison.decode!() |> List.first() |> Map.keys()

      assert basic_metadata == metadata_output
      assert conn.status == 200
    end
  end

  @doc """
  This function overwtites an image with its original version. This is done by force copying the
  intended image with the original copy. For example, the image "foo.jpg" is overwritten by the
  image "foo_original.jpg".
  """
  def reset_image(path) do
    System.cmd("cp", ["-f", String.replace(path, ".jpg", "_original.jpg"), path])
  end

  defp metadata_whitelist() do
    [
      "BitsPerSample",
      "ColorComponents",
      "Directory",
      "EncodingProcess",
      "ExifByteOrder",
      "ExifToolVersion",
      "FileAccessDate",
      "FileInodeChangeDate",
      "FileModifyDate",
      "FileName",
      "FilePermissions",
      "FileSize",
      "FileType",
      "FileTypeExtension",
      "ImageHeight",
      "ImageSize",
      "ImageWidth",
      "MIMEType",
      "Megapixels",
      "Orientation",
      "ResolutionUnit",
      "SourceFile",
      "XResolution",
      "YCbCrPositioning",
      "YResolution"
    ]
  end
end
