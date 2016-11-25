defmodule GaleServer.UnauthUserController do
  use GaleServer.Web, :controller
  alias Comeonin.Bcrypt
  alias GaleServer.User

  plug :put_view, GaleServer.JsonView

  def log_in(conn, %{"username" => username, "password" => password}) do
    case Repo.get_by(User, username: username) do
      nil -> conn
        |> put_status(400)
        |> render("error.json", payload: %{message: "Login failed"})
      user ->
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
              |> put_status(400)
              |> render("error.json", payload: %{message: "JWT error"})
          end
        else
          conn
          |> put_status(400)
          |> render("error.json", payload: %{message: "Login failed"})
        end
    end
  end

  def log_in(conn, params) do
    username_in_params = Map.has_key?(params, "username")
    password_in_params = Map.has_key?(params, "password")
    cond do
      not username_in_params and not password_in_params ->
        conn
          |> put_status(400)
          |> render("error.json", payload: %{
            message: "username and password are missing"
          })
      not username_in_params ->
        conn
          |> put_status(400)
          |> render("error.json", payload: %{message: "username is missing"})
      not password_in_params ->
        conn
          |> put_status(400)
          |> render("error.json", payload: %{message: "password is missing"})
      true ->
        conn
          |> put_status(400)
          |> render("error.json", payload: %{message: "unknown error"})
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
                id: user.id,
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
