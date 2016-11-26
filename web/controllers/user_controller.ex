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
    {:ok, friend} = User.get_by_username(friend_username)
    outgoing_friend_req = Repo.one(FriendReq, user_id: user.id,
      friend_id: friend.id)
    incoming_friend_req = Repo.one(FriendReq, user_id: friend.id,
      friend_id: user.id)
    friend_rel = Repo.one(Friend, user_id: user.id, friend_id: friend.id)
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
    valid = with {:ok, friend} <-
      (case User.get_by_username(username) do
        {:ok, friend} -> {:ok, friend}
        {:error, err_msg} -> {:error, 404, err_msg}
      end),
      {:ok} <-
        (case friend_req_exists?(user, username) do
          {:ok} -> {:ok}
          {:error, err_msg} -> {:error, 400, err_msg}
        end),
      do: {:ok, friend}
    case valid do
      {:error, err_code, err_msg} -> conn
        |> put_status(err_code)
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
      where: f.user_id == ^user.id or f.friend_id == ^user.id,
      preload: [:user, :friend])
    friend_reqs = Enum.map(friend_reqs, fn (x) -> %{
      id: x.id,
      user: x.user.username,
      friend: x.friend.username,
      inserted_at: x.inserted_at
    } end)
    conn
    |> put_status(200)
    |> render("ok.json", payload: friend_reqs)
  end

  def get_friend_req(conn, %{"freq_id" => freq_id}) do
    user = Guardian.Plug.current_resource(conn)
    valid = with {:ok, friend_req} <-
      (case Repo.one(from f in FriendReq,
        join: u1 in User, on: f.user_id == u1.id,
        join: u2 in User, on: f.friend_id == u2.id,
        where: (f.user_id == ^user.id or f.friend_id == ^user.id)
          and f.id == ^freq_id,
        preload: [:user, :friend]) do
          nil -> {:error, 400, "You cannot access friend request id ${freq_id}"}
          friend_req -> {:ok, friend_req}
        end),
      do: {:ok, friend_req}
    case valid do
      {:error, err_code, err_msg} ->
        conn
        |> put_status(err_code)
        |> render("error.json", payload: %{
          message: err_msg
        })
      {:ok, friend_req} ->
        conn
        |> put_status(200)
        |> render("ok.json", payload: %{
          id: friend_req.id,
          user: friend_req.user.username,
          friend: friend_req.friend.username,
          inserted_at: friend_req.inserted_at
        })
    end
  end

  def update_friend_req(conn, %{"freq_id" => freq_id, "action" => action})
    when action == "accept" or action == "reject" or action == "cancel" do
    user = Guardian.Plug.current_resource(conn)
    valid = with {:ok, friend_req} <-
      (case Repo.one(from f in FriendReq,
        join: u1 in User, on: f.user_id == u1.id,
        join: u2 in User, on: f.friend_id == u2.id,
        where: (u1.id == ^user.id or u2.id == ^user.id) and f.id == ^freq_id,
        preload: [:user, :friend]) do
          nil -> {:error, 400, "You cannot access friend request id ${freq_id}"}
          friend_req -> {:ok, friend_req}
        end),
      {:ok} <-
        (case action do
          "accept" ->
            if friend_req.user.id == user.id do
              {:error, 400, "You cannot accept your own friend request"}
            else
              {:ok}
            end
          "reject" ->
            if friend_req.user.id == user.id do
              {:error, 400, "You cannot reject your own friend request"}
            else
              {:ok}
            end
          "cancel" ->
            if friend_req.friend.id == user.id do
              {:error, 400, "You cannot cancel a friend request that you didn't
                send"}
            else
              {:ok}
            end
        end),
      do: {:ok, friend_req}
    case valid do
      {:error, err_code, err_msg} ->
        conn
        |> put_status(err_code)
        |> render("error.json", payload: %{
          message: err_msg
        })
      {:ok, friend_req} ->
        case Repo.delete(friend_req) do
          {:ok, friend_req} ->
            case action do
              "accept" ->
                friend_req = %Friend{}
                |> Friend.changeset()
                |> Changeset.put_assoc(:user, friend_req.user)
                |> Changeset.put_assoc(:friend, friend_req.friend)
                |> Repo.insert!()
                %Friend{}
                |> Friend.changeset()
                |> Changeset.put_assoc(:user, friend_req.friend)
                |> Changeset.put_assoc(:friend, friend_req.user)
                |> Repo.insert!()
                conn
                |> put_status(200)
                |> render("ok.json", payload: %{
                  id: friend_req.id,
                  user: friend_req.user.username,
                  friend: friend_req.friend.username,
                  inserted_at: friend_req.inserted_at
                })
              "reject" ->
                conn
                |> put_status(200)
                |> render("ok.json")
              "cancel" ->
                conn
                |> put_status(200)
                |> render("ok.json")
            end
          {:error, _} ->
            conn
            |> put_status(500)
            |> render("error.json", payload: %{message: "Error removing friend
              request id #{friend_req.id}"})
        end
    end
  end

  def update_friend_req(conn, %{"freq_id" => _, "action" => _}) do
    conn
    |> put_status(400)
    |> render("error.json", payload: %{message: "action must be \"accept\",
      \"reject\", or \"cancel\""})
  end

  def update_friend_req(conn, %{"freq_id" => _}) do
    conn
    |> put_status(400)
    |> render("error.json", payload: %{message: "Missing action field"})
  end
end
