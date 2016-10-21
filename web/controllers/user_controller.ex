defmodule GaleServer.UserController do
  use GaleServer.Web, :controller
  alias GaleServer.User

  def get_users(conn, _params) do
    render conn, "users.json", users: Repo.all(User)
  end

  def make_user(conn, post_params) do
    changeset = User.changeset(%User{}, post_params)
    case Repo.insert(changeset) do
      {:ok, user} ->
        render conn, "ok.json", user: user
      {:error, changeset} ->
        render conn, "err.json", payload: changeset
    end
  end
end
