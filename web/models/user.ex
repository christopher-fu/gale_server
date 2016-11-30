defmodule GaleServer.User do
  use GaleServer.Web, :model
  alias Comeonin.Bcrypt
  alias GaleServer.{Repo, User, Friend, FriendReq, Event, EventUser,
    PendingEventUser}

  schema "users" do
    field :username, :string
    field :name, :string, default: ""
    field :password, :string

    has_many :_friends, Friend
    has_many :friends, through: [:_friends, :friend]

    has_many :_friend_reqs, FriendReq
    has_many :friend_reqs, through: [:_friend_reqs, :friend]

    many_to_many :events, Event, join_through: EventUser
    many_to_many :pending_events, Event, join_through: PendingEventUser

    timestamps()
  end

  def get_by_username(username) do
    case Repo.get_by(User, username: username) do
      nil -> {:error, "No user with username #{username} exists"}
      user -> {:ok, user}
    end
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  :username and :name have a max length of 256. :username and :name must not
  contain any whitespace.
  """
  def changeset(struct, params \\ %{}) do
    # Sort of awkward: handle both :password and "password" as keys in param
    password = cond do
      Map.has_key?(params, :password) -> params[:password]
      Map.has_key?(params, "password") -> params["password"]
      true -> nil
    end
    if password do
      struct
      |> cast(params, [:username, :name, :password])
      |> validate_required([:username, :password])
      |> validate_format(:username, ~r/^\S+$/)  # No whitespace
      |> validate_format(:name, ~r/^\S+$/)      # No whitespace
      |> validate_length(:username, max: 256)
      |> validate_length(:name, max: 256)
      |> unique_constraint(:username)
      |> put_change(:password, Bcrypt.hashpwsalt(password))
    else
      struct
      |> cast(params, [:username, :name, :password])
      |> validate_required([:username, :password])
      |> validate_format(:username, ~r/^\S+$/)  # No whitespace
      |> validate_format(:name, ~r/^\S+$/)      # No whitespace
      |> validate_length(:username, max: 256)
      |> validate_length(:name, max: 256)
      |> unique_constraint(:username)
    end

  end
end
