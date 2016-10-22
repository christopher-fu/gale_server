defmodule GaleServer.UserControllerTest do
  use GaleServer.ConnCase, async: true
  alias GaleServer.{Repo, User}

  test "get_users/2 responds with all users" do
    users = [User.changeset(%User{}, %{username: "chris", password: "pass"}),
             User.changeset(%User{}, %{username: "adam", password: "adampass"})]
    Enum.each users, &Repo.insert!(&1)

    response = build_conn()
      |> get("/api/users")
      |> json_response(200)

    expected = %{
      "error" => false,
      "payload" => %{
        "users" => [
          %{"username" => "chris", "name" => ""},
          %{"username" => "adam", "name" => ""}
        ]
      }
    }

    assert response == expected
  end

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
      assert user.username === "chris" and user.password === "pass"
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
      assert user.username === "chris" and user.name === "chris" and user.password === "pass"
    end
  end

  test "make_user/2 returns error on missing data" do
    response = build_conn()
      |> post("/api/users", %{username: "chris", password: "pass"})
  end
end
