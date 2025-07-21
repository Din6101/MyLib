defmodule MyLib.Repo.Migrations.CreateCredentialAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:credential) do
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:credential, [:email])

    create table(:credential_tokens) do
      add :credentials_id, references(:credential, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:credential_tokens, [:credentials_id])
    create unique_index(:credential_tokens, [:context, :token])
  end
end
