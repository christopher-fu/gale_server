defmodule GaleServer.PendingEventUser do
  use GaleServer.Web, :model
  alias GaleServer.{User, Event}

  schema "pending_event_user" do
    belongs_to :user, User
    belongs_to :event, Event
    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :event_id])
  end
end
