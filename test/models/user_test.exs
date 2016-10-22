defmodule GaleServer.UserTest do
  use GaleServer.ModelCase

  alias GaleServer.User

  @valid_attrs %{password: "pass", username: "chrisf", name: "chris"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "name is not required" do
    changeset = User.changeset(%User{}, Map.delete(@valid_attrs, :name))
    assert changeset.valid?
  end

  test "username cannot contain spaces" do
    changeset = User.changeset(%User{}, %{@valid_attrs | :username => "chris fu"})
    refute changeset.valid?
  end

  test "name cannot contain spaces" do
    changeset = User.changeset(%User{}, %{@valid_attrs | :name => "chris fu"})
    refute changeset.valid?
  end
end
