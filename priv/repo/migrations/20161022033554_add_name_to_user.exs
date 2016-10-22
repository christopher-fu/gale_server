defmodule GaleServer.Repo.Migrations.AddNameToUser do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :name, :string, default: ""
    end
  end
end
