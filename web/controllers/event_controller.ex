defmodule GaleServer.EventController do
  use GaleServer.Web, :controller
  alias GaleServer.{User, Friend, FriendReq, Event, AcceptedEventUser,
    PendingEventUser, RejectedEventUser}
  alias Ecto.Changeset

  plug :put_view, GaleServer.JsonView
  plug Guardian.Plug.EnsureAuthenticated, handler: GaleServer.AuthErrorHandler

  def event_to_json(event) do
    event = Repo.preload(event,
      [:owner, :accepted_invitees, :pending_invitees, :rejected_invitees])
    %{
      id: event.id,
      description: event.description,
      time: Timex.format!(event.time, "{ISO:Extended:Z}"),
      owner: event.owner.username,
      owner_name: event.owner.name,
      accepted_invitees: Enum.map(event.accepted_invitees, fn (x) -> %{
        username: x.username,
        name: x.name
      } end) |> Enum.sort(&(&1.username <= &2.username)),
      pending_invitees: Enum.map(event.pending_invitees, fn (x) -> %{
        username: x.username,
        name: x.name
      } end) |> Enum.sort(&(&1.username <= &2.username)),
      rejected_invitees: Enum.map(event.rejected_invitees, fn (x) -> %{
        username: x.username,
        name: x.name
      } end) |> Enum.sort(&(&1.username <= &2.username))
    }
  end

  def get_event(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)
    case Repo.get(Event, id) do
      nil ->
        conn
        |> put_status(404)
        |> render("error.json", payload: %{message: "No event with id #{id} exists"})
      event ->
        event = Repo.preload(event,
          [:owner, :accepted_invitees, :pending_invitees, :rejected_invitees])
        # A user should only be able to get an event if he owns it or if he is
        # one of the invitees
        can_view = event.owner.id == user.id or
          Enum.member?(Enum.map(event.accepted_invitees, &(&1.id == user.id)), true) or
          Enum.member?(Enum.map(event.pending_invitees, &(&1.id == user.id)), true) or
          Enum.member?(Enum.map(event.rejected_invitees, &(&1.id == user.id)), true)
        if can_view do
          conn
          |> render("ok.json", payload: event_to_json(event))
        else
          conn
          |> put_status(403)
          |> render("error.json", payload: %{message: "You cannot view event id #{id}"})
        end
    end
  end

  def make_event(conn,
    %{"description" => description, "time" => time, "invitees" => invitees})
    when is_binary(description) and is_binary(time) and is_list(invitees)
    do
    user = Guardian.Plug.current_resource(conn)
    invitees = Enum.sort(invitees)
    valid = with {:ok} <-
      (if String.length(description) > 1000 do
        {:error, 400, "description has a max length of 1000 characters"}
      else
        {:ok}
      end),
      {:ok, time} <-
        (case Timex.parse(time, "{ISO:Extended:Z}") do
          {:ok, time} ->
            {:ok, time}
          {:error, err_msg} ->
            {:error, 400, "time must a UTC time in ISO-8601 Z format with " <>
              "dashes (YYYY-MM-DDThh:mm:ssZ)"}
        end),
      {:ok} <-
        # Check that all elements in invitees are strings
        (if invitees
          |> Enum.map(&(is_binary(&1)))
          |> Enum.member?(false) do
          {:error, 400, "All elements in invitees must be strings"}
        else
          {:ok}
        end),
      {:ok, invitee_ids} <-
        # Check that all elements in invitees are usernames of existing users
        (invitee_usernames_ids = invitees
          |> Enum.map(fn (username) ->
            case Repo.get_by(User, username: username) do
              nil -> {false, username}
              inv -> {true, inv.id}
            end
          end)
        if length(Enum.filter_map(invitee_usernames_ids,
          &(not elem(&1, 0)), &(elem(&1, 1)))) > 0 do
          {:error, 400, "The following usernames are invalid: " <>
            Enum.join(invitee_usernames_ids, ", ")}
        else
          {:ok, Enum.map(invitee_usernames_ids, &(elem(&1, 1)))}
        end),
      do: {:ok, invitee_ids}
    case valid do
      {:ok, invitee_ids} ->
        event = %Event{}
        |> Event.changeset(%{owner_id: user.id, description: description, time: time})
        |> Repo.insert!()

        now = Timex.now()
        Repo.insert_all(PendingEventUser, Enum.map(invitee_ids, fn (inv_id) ->
          %{
            event_id: event.id,
            user_id: inv_id,
            inserted_at: now,
            updated_at: now
          }
        end))

        # Refresh event
        event = Repo.get!(Event, event.id)
        conn
        |> put_status(200)
        |> render("ok.json", payload: event_to_json(event))
      {:error, err_status, err_msg} ->
        conn
        |> put_status(err_status)
        |> render("error.json", payload: %{message: err_msg})
    end
  end

  def make_event(conn, _params) do
    conn
    |> put_status(400)
    |> render("error.json", payload: %{message: "Invalid POST /event request"})
  end

  def get_events(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    owned_events = Repo.all(from ev in Event,
      where: ev.owner_id == ^user.id and ev.time >= from_now(0, "second"),
      order_by: ev.time)
    accepted_events = Repo.all(from ev in Event,
      join: eu in AcceptedEventUser, on: ev.id == eu.event_id,
      join: u in User, on: u.id == eu.user_id,
      where: u.id == ^user.id and ev.time >= from_now(0, "second"),
      order_by: ev.time)
    pending_events = Repo.all(from ev in Event,
      join: eu in PendingEventUser, on: ev.id == eu.event_id,
      join: u in User, on: u.id == eu.user_id,
      where: u.id == ^user.id  and ev.time >= from_now(0, "second"),
      order_by: ev.time)
    rejected_events = Repo.all(from ev in Event,
      join: eu in RejectedEventUser, on: ev.id == eu.event_id,
      join: u in User, on: u.id == eu.user_id,
      where: u.id == ^user.id and ev.time >= from_now(0, "second"),
      order_by: ev.time)
    conn
    |> put_status(200)
    |> render("ok.json", payload: %{
      "owned_events": Enum.map(owned_events, &(event_to_json(&1))),
      "accepted_events": Enum.map(accepted_events, &(event_to_json(&1))),
      "pending_events": Enum.map(pending_events, &(event_to_json(&1))),
      "rejected_events": Enum.map(rejected_events, &(event_to_json(&1)))
    })
  end

  def update_event(conn, %{"id" => id, "action" => action})
  when action == "accept" or action == "reject" do
    user = Guardian.Plug.current_resource(conn)
    valid = with {:ok, event} <-
      (case Repo.get(Event, id)
        |> Repo.preload([:owner, :accepted_invitees,
                         :pending_invitees, :rejected_invitees]) do
        nil -> {:error, 404, "No event with id #{id} exists"}
        event -> {:ok, event}
      end),
      {:ok} <-
        (can_view = event.owner_id == user.id or
            Enum.member?(Enum.map(event.accepted_invitees, &(&1.id == user.id)), true) or
            Enum.member?(Enum.map(event.pending_invitees, &(&1.id == user.id)), true) or
            Enum.member?(Enum.map(event.rejected_invitees, &(&1.id == user.id)), true)
        if can_view do
          {:ok}
        else
          {:error, 403, "You cannot modify event id #{id}"}
        end),
      {:ok} <-
        (if event.time < Timex.now do
          {:error, 400, "You cannot modify events in the past"}
        else
          {:ok}
        end),
      {:ok} <-
        (case action do
          "accept" ->
            if event.owner_id == user.id do
              {:error, 400, "You cannot accept your own event"}
            else
              {:ok}
            end
          "reject" ->
            if event.owner_id == user.id do
              {:error, 400, "You cannot reject your own event"}
            else
              {:ok}
            end
        end),
      do: {:ok, event}
    case valid do
      {:ok, event} ->
        case action do
          "accept" ->
            Repo.delete_all(from eu in PendingEventUser,
              where: eu.event_id == ^id and eu.user_id == ^user.id)
            %AcceptedEventUser{}
            |> AcceptedEventUser.changeset(%{event_id: id, user_id: user.id})
            |> Repo.insert!()
            event = Repo.get!(Event, event.id)
            conn
            |> put_status(200)
            |> render("ok.json", payload: event_to_json(event))
          "reject" ->
            Repo.delete_all(from eu in PendingEventUser,
              where: eu.event_id == ^id and eu.user_id == ^user.id)
            %RejectedEventUser{}
            |> RejectedEventUser.changeset(%{event_id: id, user_id: user.id})
            |> Repo.insert!()
            conn
            |> put_status(200)
            |> render("ok.json", payload: event_to_json(event))
        end
      {:error, err_status, err_msg} ->
        conn
        |> put_status(err_status)
        |> render("error.json", payload: %{message: err_msg})
    end
  end

  def delete_event(conn, %{"id" => id}) do
    user = Guardian.Plug.current_resource(conn)
    valid = with {:ok, event} <-
      (case Repo.get(Event, id) do
        nil -> {:error, 404, "No event with id #{id} exists"}
        event -> {:ok, event}
      end),
      {:ok} <-
        (if event.owner_id == user.id do
          {:ok}
        else
          {:error, 403, "Only the owner of an event can cancel it"}
        end),
      do: {:ok, event}
    case valid do
      {:ok, event} ->
        Repo.delete!(event)
        conn
        |> put_status(200)
        |> render("ok.json")
      {:error, err_status, err_msg} ->
        conn
        |> put_status(err_status)
        |> render("error.json", payload: %{message: err_msg})
    end
  end
end
