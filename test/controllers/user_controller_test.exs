defmodule GaleServer.UserControllerTest do
  use GaleServer.ConnCase, async: true
  alias GaleServer.{Repo, User}

  test "get_users/2 responds with all users" do
    users = [User.changeset(%User{}, %{username: "chris", password: "pass"}),
             User.changeset(%User{}, %{username: "adam", password: "adampass"})]
    Enum.each users, &Repo.insert!(&1)

    %{"payload" => %{"jwt" => jwt}} = build_conn()
      |> post("/api/login", %{username: "chris", password: "pass"})
      |> json_response(200)

    response = build_conn()
      |> put_req_header("authorization", jwt)
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
end
