defmodule GaleServer.EventController do
  use GaleServer.Web, :controller
  alias GaleServer.{User, Friend, FriendReq, Event, PendingEventUser}
  alias Ecto.Changeset

  plug :put_view, GaleServer.JsonView
  plug Guardian.Plug.EnsureAuthenticated, handler: GaleServer.AuthErrorHandler

  defp event_to_json(event) do
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
          {:error, err_msg} -> {:error, 400, err_msg}
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
end
