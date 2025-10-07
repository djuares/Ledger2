defmodule Ledger.Repo.Migrations.CreateMoney do
  use Ecto.Migration

  def change do
    create table(:money) do
      add :name, :string
      add :price, :float

      timestamps()
    end

    # Si quieres asegurar que los nombres sean únicos
    create unique_index(:money, [:name])

    # Índice para búsquedas por precio si es necesario
    create index(:money, [:price])
  end
end
