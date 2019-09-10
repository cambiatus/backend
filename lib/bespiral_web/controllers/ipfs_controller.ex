defmodule BeSpiralWeb.IPFSController do
  use BeSpiralWeb, :controller

  def save(conn, params) do
    [conn: ipfs] = :bespiral |> Application.get_env(:ipfs)

    ipfs_conn =
      IPFS.API.conn()
      |> Map.merge(ipfs)

    with %{path: file_path} = Map.get(params, "file"),
         {:ok, %{hash: hash}} <- IPFS.API.add(ipfs_conn, file_path) do
      json(conn, %{data: %{hash: hash}})
    else
      nil ->
        conn
        |> put_status(422)
        |> json(%{error: "File is required"})

      _ ->
        conn
        |> put_status(500)
        |> json(%{error: "Something went wrong while uploading your image"})
    end
  end
end
