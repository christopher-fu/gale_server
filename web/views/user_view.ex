defmodule GaleServer.UserView do
  use GaleServer.Web, :view

  def render("users.json", %{users: users}) do
    %{users: render_many(users, GaleServer.UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    %{username: user.username}
  end

  def render("ok.json", %{payload: payload}) do
    %{error: false, payload: payload}
  end

  def render("ok.json", _params) do
    %{error: false}
  end

  def render("error.json", %{payload: payload}) do
    %{error: true, payload: payload}
  end

  def render("error.json", _params) do
    %{error: true}
  end
end
