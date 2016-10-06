defmodule GaleServer.UserController do
  use GaleServer.Web, :controller

  def get_users(conn, _params) do
    render conn, "users.json", users: [%{username: "chris"}, %{username: "adam"}, %{username: "ken"}]
  end
end
