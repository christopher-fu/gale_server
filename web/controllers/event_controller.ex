defmodule GaleServer.EventController do
  use GaleServer.Web, :controller
  alias GaleServer.{User, Friend, FriendReq}
  alias Ecto.Changeset

  plug :put_view, GaleServer.JsonView
  plug Guardian.Plug.EnsureAuthenticated, handler: GaleServer.AuthErrorHandler

  def get_event(conn, _params) do
    render(conn, "ok.json", payload: %{})
  end
end
