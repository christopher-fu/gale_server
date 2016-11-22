defmodule GaleServer.Friend do
  use GaleServer.Web, :model
  alias GaleServer.User

  schema "friends" do
    belongs_to :user, User
    belongs_to :friend, User
    # status is either 0 for pending, 1 for accepted, or 2 for rejected
    field :status, :integer, default: 0
    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  :status must be 0, 1, or 2.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:status])
    |> validate_required([:status])
    |> validate_inclusion(:status, 0..2)
  end
end
