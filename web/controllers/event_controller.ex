defmodule GaleServer.EventController do
  use GaleServer.Web, :controller
  alias GaleServer.{User, Friend, FriendReq, Event}
  alias Ecto.Changeset

  plug :put_view, GaleServer.JsonView
  plug Guardian.Plug.EnsureAuthenticated, handler: GaleServer.AuthErrorHandler

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
          |> render("ok.json", payload: %{
            id: event.id,
            description: event.description,
            time: event.time,
            owner: event.owner.username,
            owner_name: event.owner.name,
            accepted_invitees: Enum.map(event.accepted_invitees, fn (x) -> %{
              username: x.username,
              name: x.name
            } end),
            pending_invitees: Enum.map(event.pending_invitees, fn (x) -> %{
              username: x.username,
              name: x.name
            } end),
            rejected_invitees: Enum.map(event.rejected_invitees, fn (x) -> %{
              username: x.username,
              name: x.name
            } end)
          })
        else
          conn
          |> put_status(403)
          |> render("error.json", payload: %{message: "You cannot view event id #{id}"})
        end
    end
  end
end
