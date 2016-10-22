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
      "users" => [
        %{"username" => "chris"},
        %{"username" => "adam"}
      ]
    }

    assert response == expected
  end
end
