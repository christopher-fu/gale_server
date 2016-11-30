defmodule GaleServer.Repo.Migrations.AddEvent do
  use Ecto.Migration

  def change do
    create table(:events) do
      add :owner_id, references(:users)
      add :description, :string, default: ""
      add :time, :datetime
      timestamps()
    end

    create table(:accepted_event_user) do
      add :user_id, references(:users), primary_key: true
      add :event_id, references(:events), primary_key: true
      timestamps()
    end

    create table(:pending_event_user) do
      add :user_id, references(:users), primary_key: true
      add :event_id, references(:events), primary_key: true
      timestamps()
    end

    create table(:rejected_event_user) do
      add :user_id, references(:users), primary_key: true
      add :event_id, references(:events), primary_key: true
      timestamps()
    end
  end
end
