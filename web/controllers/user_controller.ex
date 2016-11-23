defmodule GaleServer.UserController do
  use GaleServer.Web, :controller
  alias GaleServer.User

  plug :put_view, GaleServer.JsonView
  plug Guardian.Plug.EnsureAuthenticated, handler: GaleServer.AuthErrorHandler

  def get_user(conn, params) do
    case Repo.get_by(User, username: params["username"]) do
      nil ->
        conn
        |> put_status(404)
        |> render("error.json", payload: %{
          message: "No user with username #{params["username"]} exists"
        })
      user ->
        conn
        |> put_status(200)
        |> render("ok.json", payload: %{
          username: user.username,
          name: user.name,
          id: user.id
        })
    end
  end
end
