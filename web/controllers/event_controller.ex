defmodule GaleServer.EventController do
  use GaleServer.Web, :controller
  alias GaleServer.{User, Friend, FriendReq, Event}
  alias Ecto.Changeset

  plug :put_view, GaleServer.JsonView
  plug Guardian.Plug.EnsureAuthenticated, handler: GaleServer.AuthErrorHandler

  def get_event(conn, %{"id" => id}) do
    case Repo.get(Event, id) do
      nil ->
        conn
        |> put_status(404)
        |> render("error.json", payload: %{message: "No event with id #{id} exists"})
      event ->
        event = Repo.preload(event,
          [:owner, :accepted_invitees, :pending_invitees, :rejected_invitees])
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
    end
  end
end
