defmodule GaleServer.UserControllerTest do
  use GaleServer.ConnCase, async: true
  alias GaleServer.{Repo, User, Friend}
  alias Ecto.Changeset

  setup do
    users = [
      User.changeset(%User{}, %{username: "chris", password: "pass"}),
      User.changeset(%User{}, %{username: "adam", password: "adampass"})
    ]
    [chris, adam] = Enum.map(users, &Repo.insert!(&1))

    %{"payload" => %{"jwt" => chris_jwt}} = build_conn()
      |> post("/api/login", %{username: "chris", password: "pass"})
      |> json_response(200)
    %{"payload" => %{"jwt" => adam_jwt}} = build_conn()
      |> post("/api/login", %{username: "adam", password: "adampass"})
      |> json_response(200)

    [chris: chris, adam: adam, chris_jwt: chris_jwt, adam_jwt: adam_jwt]
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

  describe "add_friend/2" do
    test "adds friend", %{
      chris: chris, adam: adam, chris_jwt: chris_jwt
    } do
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/user/addfriend", %{username: "adam"})
        |> json_response(200)
      chris_to_adam = Repo.get_by(Friend, user_id: chris.id)
      adam_to_chris = Repo.get_by(Friend, user_id: adam.id)
      refute chris_to_adam == nil
      refute adam_to_chris == nil
      refute response["error"]
      assert Map.has_key?(response["payload"], "inserted_at")
    end

    test "errors on nonexistent friend", %{chris_jwt: chris_jwt} do
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("api/user/addfriend", %{username: "asdf"})
        |> json_response(400)
      assert response["error"]
      assert Map.has_key?(response["payload"], "message")
    end

    test "errors when trying to send a duplicate friend request", %{
      chris: chris,
      adam: adam,
      chris_jwt: chris_jwt
    } do
      %Friend{}
      |> Friend.changeset(%{status: 0})
      |> Changeset.put_assoc(:user, chris)
      |> Changeset.put_assoc(:friend, adam)
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/user/addfriend", %{username: adam.username})
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
      |> Friend.changeset(%{status: 1})
      |> Changeset.put_assoc(:user, chris)
      |> Changeset.put_assoc(:friend, adam)
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/user/addfriend", %{username: adam.username})
        |> json_response(400)
      assert response["error"]
      assert Map.has_key?(response["payload"], "message")
    end
  end
end
