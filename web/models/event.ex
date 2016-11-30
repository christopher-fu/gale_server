defmodule GaleServer.Event do
  use GaleServer.Web, :model
  alias GaleServer.{User, AcceptedEventUser, PendingEventUser,
    RejectedEventUser}

  schema "events" do
    field :description, :string, default: ""
    field :time, Timex.Ecto.DateTime

    belongs_to :owner, User
    many_to_many :accepted_invitees, User, join_through: AcceptedEventUser
    many_to_many :pending_invitees, User, join_through: PendingEventUser
    many_to_many :rejected_invitees, User, join_through: RejectedEventUser
    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:owner_id, :description, :time])
    |> validate_required([:owner_id, :time])
    |> validate_length(:description, max: 256)
  end
end

defmodule GaleServer.AcceptedEventUser do
  use GaleServer.Web, :model
  alias GaleServer.{User, Event}

  schema "accepted_event_user" do
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

defmodule GaleServer.RejectedEventUser do
  use GaleServer.Web, :model
  alias GaleServer.{User, Event}

  schema "rejected_event_user" do
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
