defmodule GaleServer.Repo.Migrations.AddFriends do
  use Ecto.Migration

  def change do
    create table(:friends, primary_key: false) do
      add :user_id, references(:users), primary_key: true
      add :friend_id, references(:users), primary_key: true

      timestamps()
    end
  end
end
