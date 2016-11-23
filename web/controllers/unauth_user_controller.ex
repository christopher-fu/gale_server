defmodule GaleServer.UnauthUserController do
  use GaleServer.Web, :controller
  alias Comeonin.Bcrypt
  alias GaleServer.User

  plug :put_view, GaleServer.JsonView

  def log_in(conn, %{"username" => username, "password" => password}) do
    user = Repo.get_by!(User, username: username)
    if Bcrypt.checkpw(password, user.password) do
      new_conn = Guardian.Plug.api_sign_in(conn, user)
      jwt = Guardian.Plug.current_token(new_conn)
      case Guardian.Plug.claims(new_conn) do
        {:ok, claims} ->
          exp = claims["exp"]
          new_conn
          |> put_resp_header("authorization", "Bearer #{jwt}")
          |> put_resp_header("x-expires", Integer.to_string(exp))
          |> render("ok.json", payload: %{jwt: jwt, exp: exp})
        {:error, _} ->
          conn
          |> put_status(401)
          |> render("error.json", payload: %{message: "JWT error"})
      end
    else
      conn
      |> put_status(401)
      |> render("error.json", payload: %{message: "Login failed"})
    end
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
          |> render("error.json", payload: Enum.into(Enum.map(changeset.errors,
            fn {k, v} -> {k, elem(v, 0)} end), %{}))
    end
  end
end
