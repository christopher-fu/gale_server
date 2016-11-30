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
Repo.insert! FriendReq.changeset(%FriendReq{},
  %{user_id: chris.id, friend_id: adam.id})
Repo.insert! Friend.changeset(%Friend{},
  %{user_id: bob.id, friend_id: chris.id})
Repo.insert! Friend.changeset(%Friend{},
  %{user_id: chris.id, friend_id: bob.id})
