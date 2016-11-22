defmodule GaleServer.FriendTest do
  use GaleServer.ModelCase

  alias GaleServer.Friend

  test "changeset with valid status" do
    changeset = Friend.changeset(%Friend{}, %{status: 0})
    assert changeset.valid?
    changeset = Friend.changeset(%Friend{}, %{status: 1})
    assert changeset.valid?
    changeset = Friend.changeset(%Friend{}, %{status: 2})
    assert changeset.valid?
  end

  test "changeset with invalid status" do
    changeset = Friend.changeset(%Friend{}, %{status: -1})
    refute changeset.valid?
    changeset = Friend.changeset(%Friend{}, %{status: 3})
    refute changeset.valid?
  end
end
