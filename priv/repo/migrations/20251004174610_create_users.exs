defmodule Ledger.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :birth_date, :date
      add :edit_date, :date

      # normally you would not make this nullable - we did this here
      # just to simplify some examples
      timestamps null: true
    end
    create unique_index(:users, [:username])
end

  end
