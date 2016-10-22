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
        conn
          |> put_status(201)
          |> render("ok.json", payload: %{
               user: %{
                username: user.username,
               }
             })
      {:error, changeset} ->
        conn
          |> put_status(400)
          |> render("err.json", payload: changeset[:errors])
    end
  end
end
