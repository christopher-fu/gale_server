defmodule GaleServer.UnauthUserControllerTest do
  use GaleServer.ConnCase, async: true
  alias GaleServer.{Repo, User}
  alias Comeonin.Bcrypt

  describe "log_in/2" do
    test "logs in an existing user" do
      Repo.insert!(User.changeset(%User{}, %{
        username: "chris", password: "pass"
      }))
      response = build_conn()
        |> post("/api/login", %{username: "chris", password: "pass"})
        |> json_response(200)

      assert Map.has_key?(response["payload"], "jwt")
        and Map.has_key?(response["payload"], "exp")
    end

    test "errors when trying to log in a nonexistent user" do
      response = build_conn()
        |> post("/api/login", %{username: "chris", password: "pass"})
        |> json_response(400)
      assert response["error"]
    end

    test "errors when missing fields" do
      response = build_conn()
        |> post("/api/login", %{username: "chris"})
        |> json_response(400)
      assert response["error"]
    end
  end

  describe "make_user/2" do
    test "creates a new user with username and password" do
      response = build_conn()
        |> post("/api/user", %{username: "chris", password: "pass"})
        |> json_response(201)

      chris = Repo.get_by!(User, username: "chris")

      expected = %{
        "error" => false,
        "payload" => %{
          "user" => %{
            "id" => chris.id,
            "username" => chris.username,
            "name" => chris.name
          }
        }
      }

      assert response == expected
      assert chris.username == "chris" and Bcrypt.checkpw("pass", chris.password)
    end

    test "creates a new user with username, name, and password" do
      response = build_conn()
        |> post("/api/user", %{username: "chris", name: "chris", password: "pass"})
        |> json_response(201)

      chris = Repo.get_by!(User, username: "chris")

      expected = %{
        "error" => false,
        "payload" => %{
          "user" => %{
            "id" => chris.id,
            "username" => chris.username,
            "name" => chris.name
          }
        }
      }

      assert response == expected
      assert chris.username == "chris" and chris.name == "chris" and
        Bcrypt.checkpw("pass", chris.password)
    end
  end

  test "make_user/2 returns error on missing data" do
    response = build_conn()
      |> post("/api/user", %{})
      |> json_response(400)

    expected = %{
      "error" => true,
      "payload" => %{
        "username" => "can't be blank",
        "password" => "can't be blank"
      }
    }

    assert response == expected
  end

  test "make_user/2 returns error when username is already taken" do
    Repo.insert!(User.changeset(%User{}, %{
      username: "chris", password: "pass"
    }))

    response = build_conn()
      |> post("/api/user", %{username: "chris", password: "anotherpass"})
      |> json_response(400)

    expected = %{
      "error" => true,
      "payload" => %{
        "username" => "has already been taken"
      }
    }

    assert response == expected
  end
end
