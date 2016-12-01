defmodule GaleServer.Friend do
  use GaleServer.Web, :model
  alias GaleServer.User

  @primary_key false
  schema "friends" do
    belongs_to :user, User, primary_key: true
    belongs_to :friend, User, primary_key: true
    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :friend_id])
  end
end

defmodule GaleServer.FriendReq do
  use GaleServer.Web, :model
  alias GaleServer.User

  schema "friend_reqs" do
    belongs_to :user, User
    belongs_to :friend, User
    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:user_id, :friend_id])
  end
end
