defmodule GaleServer.EventControllerTest do
  use GaleServer.ConnCase, async: true
  alias GaleServer.{Repo, User, Friend, FriendReq, Event, AcceptedEventUser,
    PendingEventUser, RejectedEventUser}
  use Timex

  setup do
    users = [
      User.changeset(%User{}, %{username: "adam", password: "adampass"}),
      User.changeset(%User{}, %{username: "bob", password: "bobpass"}),
      User.changeset(%User{}, %{username: "chris", password: "pass"}),
      User.changeset(%User{}, %{username: "dan", password: "danpass"}),
      User.changeset(%User{}, %{username: "ed", password: "edpass"}),
    ]
    [adam, bob, chris, dan, ed] = Enum.map(users, &Repo.insert!(&1))

    events = [
      Event.changeset(%Event{},
        %{owner_id: chris.id, description: "event 1", time: Timex.now}),
      Event.changeset(%Event{},
        %{owner_id: adam.id, description: "event 2", time: Timex.now}),
    ]
    |> Enum.map(&Repo.insert!(&1))
    |> Enum.map(&Repo.preload(&1,
      [:accepted_invitees, :pending_invitees, :rejected_invitees]))

    %{"payload" => %{"jwt" => chris_jwt}} = build_conn()
      |> post("/api/login", %{username: "chris", password: "pass"})
      |> json_response(200)
    %{"payload" => %{"jwt" => adam_jwt}} = build_conn()
      |> post("/api/login", %{username: "adam", password: "adampass"})
      |> json_response(200)

    [adam: adam, bob: bob, chris: chris, dan: dan, end: ed, chris_jwt:
      chris_jwt, adam_jwt: adam_jwt, events: events]
  end

  describe "get_event/2" do
    test "gets event",
      %{adam: adam, bob: bob, chris: chris, dan: dan, chris_jwt: chris_jwt,
      events: events} do
      event = Enum.at(events, 0)
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/event/#{event.id}")
        |> json_response(200)
      expected = %{
        "error" => false,
        "payload" => %{
          "id" => event.id,
          "description" => event.description,
          "owner" => chris.username,
          "owner_name" => chris.name,
          "time" => Timex.format!(event.time, "{ISO:Extended:Z}"),
          "accepted_invitees" => [],
          "pending_invitees" => [],
          "rejected_invitees" => []
        }
      }
      assert response == expected

      # Add adam as an accepted user
      %AcceptedEventUser{}
      |> AcceptedEventUser.changeset(%{user_id: adam.id, event_id: event.id})
      |> Repo.insert!()
      # Add bob as a pending user
      %PendingEventUser{}
      |> PendingEventUser.changeset(%{user_id: bob.id, event_id: event.id})
      |> Repo.insert!()
      # Add dan as a rejected user
      %RejectedEventUser{}
      |> RejectedEventUser.changeset(%{user_id: dan.id, event_id: event.id})
      |> Repo.insert!()

      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/event/#{event.id}")
        |> json_response(200)
      expected = %{
        "error" => false,
        "payload" => %{
          "id" => event.id,
          "description" => event.description,
          "owner" => chris.username,
          "owner_name" => chris.name,
          "time" => Timex.format!(event.time, "{ISO:Extended:Z}"),
          "accepted_invitees" => [%{
            "username" => adam.username,
            "name" => adam.name
          }],
          "pending_invitees" => [%{
            "username" => bob.username,
            "name" => bob.name
          }],
          "rejected_invitees" => [%{
            "username" => dan.username,
            "name" => dan.name
          }],
        }
      }
    end

    test "denies request if user is not owner or invited",
      %{adam: adam, chris: chris, chris_jwt: chris_jwt, events: events} do
      event = Enum.at(events, 1)
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/event/#{event.id}")
        |> json_response(403)
      expected = %{
        "error" => true,
        "payload" => %{
          "message" => "You cannot view event id #{event.id}"
        }
      }
      assert response == expected

      %AcceptedEventUser{}
      |> AcceptedEventUser.changeset(%{user_id: chris.id, event_id: event.id})
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/event/#{event.id}")
        |> json_response(200)
      expected = %{
        "error" => false,
        "payload" => %{
          "id" => event.id,
          "description" => event.description,
          "owner" => adam.username,
          "owner_name" => adam.name,
          "time" => Timex.format!(event.time, "{ISO:Extended:Z}"),
          "accepted_invitees" => [%{
            "username" => chris.username,
            "name" => chris.name
          }],
          "pending_invitees" => [],
          "rejected_invitees" => [],
        }
      }
      assert response == expected
    end
  end
end