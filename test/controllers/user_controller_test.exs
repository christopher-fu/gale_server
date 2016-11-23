defmodule GaleServer.UserControllerTest do
  use GaleServer.ConnCase, async: true
  alias GaleServer.{Repo, User}

  test "get_user/2 responds with the requested user" do
    users = [User.changeset(%User{}, %{username: "chris", password: "pass"}),
             User.changeset(%User{}, %{username: "adam", password: "adampass"})]
    [chris, _] = Enum.map users, &Repo.insert!(&1)

    %{"payload" => %{"jwt" => jwt}} = build_conn()
      |> post("/api/login", %{username: "chris", password: "pass"})
      |> json_response(200)

    response = build_conn()
      |> put_req_header("authorization", jwt)
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
end
