defmodule MyLib.Repo.Migrations.CreateLoans do
  use Ecto.Migration

  def change do
    create table(:loans) do
      add :borrows_at, :naive_datetime
      add :due_at, :naive_datetime
      add :returned_at, :naive_datetime
      add :user_id, references(:users, on_delete: :nothing)
      add :book_id, references(:books, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end
  end
end
