defmodule GaleServer.UserController do
  use GaleServer.Web, :controller
  alias GaleServer.User

  plug :put_view, GaleServer.JsonView
  plug Guardian.Plug.EnsureAuthenticated, handler: GaleServer.AuthErrorHandler

  def get_users(conn, _params) do
    render conn, "ok.json", payload: %{
      users: Enum.map(Repo.all(User), fn(user) ->
        %{username: user.username, name: user.name}
      end)
    }
  end
end
