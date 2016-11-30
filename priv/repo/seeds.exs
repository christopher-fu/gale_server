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

alias GaleServer.{Repo, User, Friend, FriendReq, Event, AcceptedEventUser,
  PendingEventUser, RejectedEventUser}
alias Ecto.Changeset

Repo.delete_all(FriendReq)
Repo.delete_all(Friend)
Repo.delete_all(Event)
Repo.delete_all(AcceptedEventUser)
Repo.delete_all(PendingEventUser)
Repo.delete_all(RejectedEventUser)
Repo.delete_all(User)

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

event = Repo.insert! Event.changeset(%Event{}, %{owner_id: chris.id,
  description: "An event!", time: Timex.now})
Repo.insert! AcceptedEventUser.changeset(%AcceptedEventUser{}, %{user_id: adam.id,
  event_id: event.id})
Repo.insert! PendingEventUser.changeset(%PendingEventUser{}, %{user_id: bob.id,
  event_id: event.id})
