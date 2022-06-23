defmodule CambiatusWeb.UploadControllerTest do
  use Cambiatus.DataCase
  use CambiatusWeb.ConnCase

  alias Cambiatus.Repo

  @test_image_path Path.join(File.cwd!(), "/test/assets/")

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "*/*")}
  end

  describe "Uploads" do
    setup :valid_community_and_user

    test "upload an image",
         %{conn: conn} do
      filename = "owlbear.jpg"

      upload = %Plug.Upload{
        path: Path.join(@test_image_path, filename),
        filename: filename,
        content_type: "image/jpeg"
      }

      conn = post(conn, "/api/upload", %{:file => upload})

      assert conn.status == 200
    end

    test "remove metada from an image",
         %{conn: conn} do
      filename = "white_cube.jpg"

      upload = %Plug.Upload{
        path: Path.join(@test_image_path, filename),
        filename: filename,
        content_type: "image/jpeg"
      }

      conn = post(conn, "/api/upload", %{:file => upload})
    end
  end
end
