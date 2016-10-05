defmodule GaleServer.UserView do
  use GaleServer.Web, :view

  def render("users.json", %{users: users}) do
    %{data: render_many(users, GaleServer.UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{username: user.username}
  end
end
