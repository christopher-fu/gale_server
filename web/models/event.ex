defmodule GaleServer.Event do
  use GaleServer.Web, :model
  alias GaleServer.{User, EventUser, PendingEventUser}

  schema "events" do
    belongs_to :owner, User
    many_to_many :invitees, User, join_through: EventUser
    many_to_many :pending_invitees, User, join_through: PendingEventUser
    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:owner_id])
  end
end
