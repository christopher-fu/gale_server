defmodule GaleServer.Repo.Migrations.AddFriendReqs do
  use Ecto.Migration

  def change do
    create table(:friend_reqs) do
      add :user_id, references(:users, on_delete: :delete_all), primary_key: true
      add :friend_id, references(:users, on_delete: :delete_all), primary_key: true
      timestamps()
    end
  end
end
