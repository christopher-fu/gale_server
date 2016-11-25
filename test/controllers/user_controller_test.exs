defmodule GaleServer.UserControllerTest do
  use GaleServer.ConnCase, async: true
  alias GaleServer.{Repo, User, Friend, FriendReq}
  alias Ecto.Changeset

  setup do
    users = [
      User.changeset(%User{}, %{username: "chris", password: "pass"}),
      User.changeset(%User{}, %{username: "adam", password: "adampass"}),
      User.changeset(%User{}, %{username: "bob", password: "bobpass"})
    ]
    [chris, adam, bob] = Enum.map(users, &Repo.insert!(&1))

    %{"payload" => %{"jwt" => chris_jwt}} = build_conn()
      |> post("/api/login", %{username: "chris", password: "pass"})
      |> json_response(200)
    %{"payload" => %{"jwt" => adam_jwt}} = build_conn()
      |> post("/api/login", %{username: "adam", password: "adampass"})
      |> json_response(200)

    [chris: chris, adam: adam, chris_jwt: chris_jwt, adam_jwt: adam_jwt,
      bob: bob]
  end

  describe "get_user/2" do
    test "responds with the requested user", %{
      chris: chris, chris_jwt: chris_jwt
    } do
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/user/chris")
        |> json_response(200)
      expected = %{
        "error" => false,
        "payload" => %{
          "id" => chris.id,
          "username" => chris.username,
          "name" => chris.name
        }
      }

      assert response == expected
    end

    test "responds with error when user does not exist",
      %{chris_jwt: chris_jwt} do
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/user/asdf")
        |> json_response(404)
      assert response["error"]
      assert Map.has_key?(response["payload"], "message")
    end
  end

  describe "send_friend_req/2" do
    test "sends friend request", %{
      chris: chris, chris_jwt: chris_jwt
    } do
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/friendreq", %{username: "adam"})
        |> json_response(200)
      chris_to_adam = Repo.get_by(FriendReq, user_id: chris.id)
      refute chris_to_adam == nil
      refute response["error"]
      assert Map.has_key?(response["payload"], "inserted_at")
    end

    test "errors on nonexistent friend", %{chris_jwt: chris_jwt} do
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/friendreq", %{username: "asdf"})
        |> json_response(404)
      assert response["error"]
      assert Map.has_key?(response["payload"], "message")
    end

    test "errors when trying to send a duplicate outgoing friend request", %{
      chris: chris,
      adam: adam,
      chris_jwt: chris_jwt
    } do
      %FriendReq{}
      |> FriendReq.changeset(%{})
      |> Changeset.put_assoc(:user, chris)
      |> Changeset.put_assoc(:friend, adam)
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/friendreq", %{username: adam.username})
        |> json_response(400)
      assert response["error"]
      assert Map.has_key?(response["payload"], "message")
    end

    test "errors when trying to send an outgoing friend request when there is
    an existing incoming friend request", %{
      chris: chris,
      adam: adam,
      chris_jwt: chris_jwt
    } do
      %FriendReq{}
      |> FriendReq.changeset(%{})
      |> Changeset.put_assoc(:user, adam)
      |> Changeset.put_assoc(:friend, chris)
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/friendreq", %{username: adam.username})
        |> json_response(400)
      assert response["error"]
      assert Map.has_key?(response["payload"], "message")
    end

    test "errors when trying to send a friend request to an existing friend", %{
      chris: chris,
      adam: adam,
      chris_jwt: chris_jwt
    } do
      %Friend{}
      |> FriendReq.changeset(%{})
      |> Changeset.put_assoc(:user, chris)
      |> Changeset.put_assoc(:friend, adam)
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/friendreq", %{username: adam.username})
        |> json_response(400)
      assert response["error"]
      assert Map.has_key?(response["payload"], "message")
    end
  end

  describe "get_friend_reqs/2" do
    test "gets all friend requests", %{
      chris: chris, chris_jwt: chris_jwt, adam: adam
    } do
      friend_req = %FriendReq{}
      |> FriendReq.changeset(%{})
      |> Changeset.put_assoc(:user, chris)
      |> Changeset.put_assoc(:friend, adam)
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/friendreq")
        |> json_response(200)
      expected = %{
        "error" => false,
        "payload" => [%{
          "id" => friend_req.id,
          "user" => chris.username,
          "friend" => adam.username,
          "inserted_at" => Ecto.DateTime.to_iso8601(friend_req.inserted_at)
        }]
      }
      assert response == expected
    end
  end

  describe "get_friend_req/2" do
    test "gets a friend request", %{
      chris: chris, chris_jwt: chris_jwt, adam: adam
    } do
      friend_req = %FriendReq{}
        |> FriendReq.changeset(%{})
        |> Changeset.put_assoc(:user, chris)
        |> Changeset.put_assoc(:friend, adam)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/friendreq/#{friend_req.id}")
        |> json_response(200)
      expected = %{
        "error" => false,
        "payload" => %{
          "id" => friend_req.id,
          "user" => chris.username,
          "friend" => adam.username,
          "inserted_at" => Ecto.DateTime.to_iso8601(friend_req.inserted_at)
        }
      }

      assert response == expected
    end

    test "errors on nonexistent friend request", %{
      chris_jwt: chris_jwt
    } do
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/friendreq/10")
        |> json_response(400)

      assert response["error"]
    end

    test "errors when trying to get another user's friend request", %{
      chris_jwt: chris_jwt, adam: adam, bob: bob
    } do
      friend_req = %FriendReq{}
        |> FriendReq.changeset()
        |> Changeset.put_assoc(:user, adam)
        |> Changeset.put_assoc(:friend, bob)
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/friendreq/#{friend_req.id}")
        |> json_response(400)
      assert response["error"]
    end
  end
end
