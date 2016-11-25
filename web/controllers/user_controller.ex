defmodule GaleServer.UserController do
  use GaleServer.Web, :controller
  alias GaleServer.{User, Friend, FriendReq}
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

  defp friend_req_exists?(user, friend_username) do
    outgoing_friend_req = Repo.one(from f in FriendReq,
      join: u1 in User, on: f.user_id == u1.id,
      join: u2 in User, on: f.friend_id == u2.id,
      where: u1.id == ^user.id and u2.username == ^friend_username)
    incoming_friend_req = Repo.one(from f in FriendReq,
      join: u1 in User, on: f.user_id == u1.id,
      join: u2 in User, on: f.friend_id == u2.id,
      where: u1.username == ^friend_username and u2.id == ^user.id)
    friend_rel = Repo.one(from f in Friend,
      join: u1 in User, on: f.user_id == u1.id,
      join: u2 in User, on: f.friend_id == u2.id,
      where: u1.id == ^user.id and u2.username == ^friend_username)
    cond do
      outgoing_friend_req != nil ->
        {:error, "You have already sent a friend request to #{friend_username}"}
      incoming_friend_req != nil ->
        {:error, "You already have a friend request from #{friend_username}"}
      friend_rel != nil ->
        {:error, "You are already friends with #{friend_username}"}
      true -> {:ok}
    end
  end

  def send_friend_req(conn, %{"username" => username}) do
    user = Guardian.Plug.current_resource(conn)
    valid = with {:ok, friend} <- User.get_by_username(username),
      {:ok} <- friend_req_exists?(user, username),
      do: {:ok, friend}
    case valid do
      {:error, err_msg} -> conn
        |> put_status(400)
        |> render("error.json", payload: %{message: err_msg})
      {:ok, friend} ->
        friend_req = FriendReq.changeset(%FriendReq{}, %{})
          |> FriendReq.changeset(%{})
          |> Changeset.put_assoc(:user, user)
          |> Changeset.put_assoc(:friend, friend)
          |> Repo.insert!()
        conn
        |> put_status(200)
        |> render("ok.json", payload: %{inserted_at: friend_req.inserted_at})
    end
  end

  def send_friend_req(conn, _params) do
    conn
    |> put_status(400)
    |> render("error.json", payload: %{message: "username is missing"})
  end

  def get_friend_reqs(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    friend_reqs = Repo.all(from f in FriendReq,
      join: u1 in User, on: f.user_id == u1.id,
      join: u2 in User, on: f.friend_id == u2.id,
      where: u1.id == ^user.id or u2.id == ^user.id,
      preload: [:user, :friend])
    friend_reqs = Enum.map(friend_reqs, fn (x) -> %{
        user: x.user.username,
        friend: x.friend.username,
        inserted_at: x.inserted_at
      }
    end)
    conn
    |> put_status(200)
    |> render("ok.json", payload: friend_reqs)
  end
end
