# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     GaleServer.Repo.insert!(%GaleServer.SomeModel{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias GaleServer.{Repo, User, Friend, FriendReq}
alias Ecto.Changeset

chris = Repo.insert! User.changeset(%User{},
  %{username: "chris", name: "chris", password: "pass"})
adam = Repo.insert! User.changeset(%User{},
  %{username: "adam", name: "adam", password: "adampass"})
bob = Repo.insert! User.changeset(%User{},
  %{username: "bob", name: "bob", password: "bobpass"})
Repo.insert! FriendReq.changeset(%FriendReq{})
  |> Changeset.put_assoc(:user, chris)
  |> Changeset.put_assoc(:friend, adam)
Repo.insert! Friend.changeset(%Friend{})
  |> Changeset.put_assoc(:user, bob)
  |> Changeset.put_assoc(:friend, chris)
Repo.insert! Friend.changeset(%Friend{})
  |> Changeset.put_assoc(:user, chris)
  |> Changeset.put_assoc(:friend, bob)
