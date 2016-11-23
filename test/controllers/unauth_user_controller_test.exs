defmodule GaleServer.UnauthUserControllerTest do
  use GaleServer.ConnCase, async: true
  alias GaleServer.{Repo, User}
  alias Comeonin.Bcrypt

  describe "make_user/2" do
    test "creates a new user with username and password" do
      response = build_conn()
        |> post("/api/users", %{username: "chris", password: "pass"})
        |> json_response(201)

      expected = %{
        "error" => false,
        "payload" => %{
          "user" => %{
            "username" => "chris",
            "name" => ""
          }
        }
      }

      assert response == expected

      user = Repo.get_by!(User, username: "chris")
      assert user.username === "chris" and Bcrypt.checkpw("pass", user.password)
    end

    test "creates a new user with username, name, and password" do
      response = build_conn()
        |> post("/api/users", %{username: "chris", name: "chris", password: "pass"})
        |> json_response(201)

      expected = %{
        "error" => false,
        "payload" => %{
          "user" => %{
            "username" => "chris",
            "name" => "chris"
          }
        }
      }

      assert response == expected

      user = Repo.get_by!(User, username: "chris")
      assert user.username === "chris" and user.name === "chris" and
        Bcrypt.checkpw("pass", user.password)
    end
  end

  test "make_user/2 returns error on missing data" do
    response = build_conn()
      |> post("/api/users", %{})
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
end
