defmodule PhoenixChat.Repo.Migrations.CreateChatTables do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :display_name, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:display_name])

    create table(:rooms) do
      add :slug, :string, null: false
      add :name, :string, null: false
      add :description, :string, null: false
      add :position, :integer, null: false, default: 0
      timestamps(type: :utc_datetime)
    end

    create unique_index(:rooms, [:slug])

    create table(:messages) do
      add :body, :text, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :room_id, references(:rooms, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:room_id, :inserted_at])
    create index(:messages, [:user_id])
  end
end
