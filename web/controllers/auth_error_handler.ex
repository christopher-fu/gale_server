defmodule GaleServer.AuthErrorHandler do
  use GaleServer.Web, :controller
  plug :put_view, GaleServer.JsonView

  def unauthenticated(conn, __params) do
    conn
    |> put_status(401)
    |> render("error.json", payload: "Unauthenticated")
  end
end
