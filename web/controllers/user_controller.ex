defmodule GaleServer.UserController do
  use GaleServer.Web, :controller
  alias GaleServer.{User, Friend}
  alias Ecto.Changeset

  plug :put_view, GaleServer.JsonView
  plug Guardian.Plug.EnsureAuthenticated, handler: GaleServer.AuthErrorHandler

  def get_user(conn, %{"username" => username}) do
    case User.get_by_username(username) do
      {:error, err_msg} -> conn
        |> put_status(404)
        |> render("error.json", payload: %{
          message: err_msg
        })
      {:ok, user} -> conn
        |> put_status(200)
        |> render("ok.json", payload: %{
          username: user.username,
          name: user.name,
          id: user.id
        })
    end
  end

  defp friend_rel_exists?(user, friend_username) do
    status = Repo.one(from f in Friend, join: u1 in User, on: f.user_id == u1.id,
      join: u2 in User, on: f.friend_id == u2.id,
      where: u1.username == ^user.username and u2.username == ^friend_username,
      select: f.status)
    case status do
      nil -> {:ok}
      0 -> {:error, "You have already sent a friend request to #{friend_username}"}
      1 -> {:error, "You are already friends with #{friend_username}"}
    end
  end

  def add_friend(conn, %{"username" => username}) do
    user = Guardian.Plug.current_resource(conn)
    valid = with {:ok, friend} <- User.get_by_username(username),
      {:ok} <- friend_rel_exists?(user, username),
      do: {:ok, friend}
    case valid do
      {:error, err_msg} -> conn
        |> put_status(400)
        |> render("error.json", payload: %{message: err_msg})
      {:ok, friend} ->
        friend_rel = %Friend{}
          |> Friend.changeset(%{status: 0})
          |> Changeset.put_assoc(:user, user)
          |> Changeset.put_assoc(:friend, friend)
          |> Repo.insert!()
        %Friend{}
        |> Friend.changeset(%{status: 0})
        |> Changeset.put_assoc(:user, friend)
        |> Changeset.put_assoc(:friend, user)
        |> Repo.insert!()
        conn
        |> put_status(200)
        |> render("ok.json", payload: %{inserted_at: friend_rel.inserted_at})
    end
  end

  def add_friend(conn, _params) do
    conn
    |> put_status(400)
    |> render("error.json", payload: %{message: "username is missing"})
  end
end
