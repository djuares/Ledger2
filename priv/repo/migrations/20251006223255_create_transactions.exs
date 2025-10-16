defmodule Ledger.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions) do
      add :timestamp, :utc_datetime
      add :origin_currency_id, references(:money)
      add :destination_currency_id, references(:money)
      add :amount, :float
      add :origin_account_id, references(:users)
      add :destination_account_id, references(:users)
      add :type, :string
      timestamps()
  end


    create index(:transactions, :timestamp)
    create index(:transactions, :origin_account_id)
    create index(:transactions, :destination_account_id)
    create index(:transactions, :origin_currency_id)
    create index(:transactions, :destination_currency_id)

  end
end
