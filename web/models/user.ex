defmodule GaleServer.User do
  use GaleServer.Web, :model

  schema "users" do
    field :username, :string
    field :name, :string, default: ""
    field :password, :string

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  :username and :name have a max length of 256. :username and :name must not
  contain any whitespace.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:username, :name, :password])
    |> validate_required([:username, :password])
    |> validate_format(:username, ~r/^\S+$/)  # No whitespace
    |> validate_format(:name, ~r/^\S+$/)      # No whitespace
    |> unique_constraint(:username)
  end
end
