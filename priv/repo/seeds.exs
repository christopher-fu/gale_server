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

alias GaleServer.{Repo, User, Friend}
alias Ecto.Changeset

chris = Repo.insert! User.changeset(%User{}, %{username: "chris", name: "chris", password: "pass"})
adam = Repo.insert! User.changeset(%User{}, %{username: "adam", name: "adam", password: "adampass"})
Repo.insert! Friend.changeset(%Friend{}, %{status: 0})
  |> Changeset.put_assoc(:user, chris)
  |> Changeset.put_assoc(:friend, adam)
Repo.insert! Friend.changeset(%Friend{}, %{status: 0})
  |> Changeset.put_assoc(:user, adam)
  |> Changeset.put_assoc(:friend, chris)
