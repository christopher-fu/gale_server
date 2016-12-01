defmodule GaleServer.EventControllerTest do
  use GaleServer.ConnCase, async: false
  alias GaleServer.{Repo, User, Friend, FriendReq, Event, AcceptedEventUser,
    PendingEventUser, RejectedEventUser, EventController}
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

    %{"payload" => %{"jwt" => chris_jwt}} = build_conn()
      |> post("/api/login", %{username: "chris", password: "pass"})
      |> json_response(200)
    %{"payload" => %{"jwt" => adam_jwt}} = build_conn()
      |> post("/api/login", %{username: "adam", password: "adampass"})
      |> json_response(200)

    [adam: adam, bob: bob, chris: chris, dan: dan, end: ed, chris_jwt:
      chris_jwt, adam_jwt: adam_jwt]
  end

  describe "get_event/2" do
    test "gets event",
      %{adam: adam, bob: bob, chris: chris, dan: dan, chris_jwt: chris_jwt} do
      event = Event.changeset(%Event{},
        %{owner_id: chris.id, description: "event 1",
          time: Timex.now |> Timex.set(microsecond: {0, 3})})
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
      %{adam: adam, chris: chris, chris_jwt: chris_jwt} do
      event = Event.changeset(%Event{},
        %{owner_id: adam.id, description: "event 2",
          time: Timex.now |> Timex.set(microsecond: {0, 3})})
        |> Repo.insert!()
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

  describe "make_event/2" do
    test "makes an event", %{chris_jwt: chris_jwt, adam: adam, bob: bob, chris: chris} do
      time = Timex.now |> Timex.set(microsecond: {0, 3})
      time_str = Timex.format!(time, "{ISO:Extended:Z}")
      post_body = %{
        description: "An event!",
        time: time_str,
        invitees: [adam.username, bob.username]
      }
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/event", post_body)
        |> json_response(200)
      event = Repo.get_by!(Event, description: "An event!", time: time)
      expected = %{
        "error" => false,
        "payload" => %{
          "id" => event.id,
          "owner" => chris.username,
          "owner_name" => chris.name,
          "description" => "An event!",
          "time" => time_str,
          "accepted_invitees" => [],
          "pending_invitees" => [
            %{
              "username" => adam.username,
              "name" => adam.name
            },
            %{
              "username" => bob.username,
              "name" => bob.name
            },
          ],
          "rejected_invitees" => []
        }
      }
      assert response == expected
    end

    test "errors when invalid time is given", %{chris_jwt: chris_jwt} do
      time = Timex.now |> Timex.set(microsecond: {0, 3})
      time_str = Timex.format!(time, "{ISO:Basic}")
      post_body = %{
        description: "An event!",
        time: time_str,
        invitees: []
      }
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> post("/api/event", post_body)
        |> json_response(400)
      expected = %{
        "error" => false,
        "payload" => %{
          "message": "time must a UTC time in ISO-8601 Z format with dashes " <>
            "(YYYY-MM-DDThh:mm:ssZ)"
        }
      }
    end
  end

  describe "get_events/2" do
    test "gets all owned events", %{chris_jwt: chris_jwt, chris: chris} do
      event1 = Event.changeset(%Event{},
        %{owner_id: chris.id, description: "event 1",
          time: Timex.now
            |> Timex.set(microsecond: {0, 3})
            |> Timex.shift(days: 7)})
        |> Repo.insert!()
      event2 = Event.changeset(%Event{},
        %{owner_id: chris.id, description: "event 1",
          time: Timex.now
            |> Timex.set(microsecond: {0, 3})
            |> Timex.shift(days: 5)})
        |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/event")
        |> json_response(200)
      expected = %{
        "error" => false,
        "payload" => %{
          "owned_events" => [
            EventController.event_to_json(event2),
            EventController.event_to_json(event1)
          ],
          "accepted_events" => [],
          "pending_events" => [],
          "rejected_events" => []
        }
      }
    end

    test "gets all accepted events",
      %{chris_jwt: chris_jwt, adam: adam, chris: chris} do
      event1 = Event.changeset(%Event{},
        %{owner_id: adam.id, description: "event 1",
          time: Timex.now
            |> Timex.set(microsecond: {0, 3})
            |> Timex.shift(days: 7)})
        |> Repo.insert!()
      event2 = Event.changeset(%Event{},
        %{owner_id: adam.id, description: "event 1",
          time: Timex.now
            |> Timex.set(microsecond: {0, 3})
            |> Timex.shift(days: 5)})
        |> Repo.insert!()
      %AcceptedEventUser{}
      |> AcceptedEventUser.changeset(%{event_id: event1.id, user_id: chris.id})
      |> Repo.insert!()
      %AcceptedEventUser{}
      |> AcceptedEventUser.changeset(%{event_id: event2.id, user_id: chris.id})
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/event")
        |> json_response(200)
      expected = %{
        "error" => false,
        "payload" => %{
          "owned_events" => [],
          "accepted_events" => [
            EventController.event_to_json(event2),
            EventController.event_to_json(event1)
          ],
          "pending_events" => [],
          "rejected_events" => []
        }
      }
    end

    test "gets all pending events",
      %{chris_jwt: chris_jwt, adam: adam, chris: chris} do
      event1 = Event.changeset(%Event{},
        %{owner_id: adam.id, description: "event 1",
          time: Timex.now
            |> Timex.set(microsecond: {0, 3})
            |> Timex.shift(days: 7)})
        |> Repo.insert!()
      event2 = Event.changeset(%Event{},
        %{owner_id: adam.id, description: "event 1",
          time: Timex.now
            |> Timex.set(microsecond: {0, 3})
            |> Timex.shift(days: 5)})
        |> Repo.insert!()
      %PendingEventUser{}
      |> PendingEventUser.changeset(%{event_id: event1.id, user_id: chris.id})
      |> Repo.insert!()
      %PendingEventUser{}
      |> PendingEventUser.changeset(%{event_id: event2.id, user_id: chris.id})
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/event")
        |> json_response(200)
      expected = %{
        "error" => false,
        "payload" => %{
          "owned_events" => [],
          "accepted_events" => [],
          "pending_events" => [
            EventController.event_to_json(event2),
            EventController.event_to_json(event1)
          ],
          "rejected_events" => []
        }
      }
    end

    test "gets all rejected events",
      %{chris_jwt: chris_jwt, adam: adam, chris: chris} do
      event1 = Event.changeset(%Event{},
        %{owner_id: adam.id, description: "event 1",
          time: Timex.now
            |> Timex.set(microsecond: {0, 3})
            |> Timex.shift(days: 7)})
        |> Repo.insert!()
      event2 = Event.changeset(%Event{},
        %{owner_id: adam.id, description: "event 1",
          time: Timex.now
            |> Timex.set(microsecond: {0, 3})
            |> Timex.shift(days: 5)})
        |> Repo.insert!()
      %RejectedEventUser{}
      |> RejectedEventUser.changeset(%{event_id: event1.id, user_id: chris.id})
      |> Repo.insert!()
      %RejectedEventUser{}
      |> RejectedEventUser.changeset(%{event_id: event2.id, user_id: chris.id})
      |> Repo.insert!()
      response = build_conn()
        |> put_req_header("authorization", chris_jwt)
        |> get("/api/event")
        |> json_response(200)
      expected = %{
        "error" => false,
        "payload" => %{
          "owned_events" => [],
          "accepted_events" => [],
          "pending_events" => [],
          "rejected_events" => [
            EventController.event_to_json(event2),
            EventController.event_to_json(event1)
          ],
        }
      }
    end
  end
end
