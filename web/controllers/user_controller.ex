defmodule GaleServer.UserController do
  use GaleServer.Web, :controller
  alias GaleServer.User

  def get_users(conn, _params) do
    render conn, "ok.json", payload: %{
      users: Enum.map(Repo.all(User), fn(user) ->
        %{username: user.username, name: user.name}
      end)
    }
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
                name: user.name
               }
             })
      {:error, changeset} ->
        conn
          |> put_status(400)
          |> render("err.json", payload: changeset[:errors])
    end
  end
end
