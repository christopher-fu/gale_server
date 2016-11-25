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
    |> cast(params, [])
  end
end