defmodule GaleServer.Repo.Migrations.AddEventUser do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :owner_id, references(:users)
      timestamps()
    end

    create table(:event_user) do
      add :user_id, references(:users), primary_key: true
      add :event_id, references(:events), primary_key: true
      timestamps()
    end
  end
end
