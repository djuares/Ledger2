defmodule Ledger.Money do
  use Ecto.Schema
  import Ecto.Changeset

  schema "money" do
    field :name, :string
    field :price, :float

    has_many :transactions_as_origin, Ledger.Transaction, foreign_key: :origin_currency_id
    has_many :transactions_as_destination, Ledger.Transaction, foreign_key: :destination_currency_id

    timestamps() # inserted_at y updated_at automáticos
  end

  @doc """
  Changeset for creating/updating a money entity.
  """
  def changeset(money, attrs) do
    money
    |> cast(attrs, [:name, :price])
    |> validate_required([:name, :price])
    |> validate_length(:name, min: 3, max: 4)
    |> update_change(:name, &String.upcase/1)
    |> unique_constraint(:name)
    |> validate_number(:price, greater_than_or_equal_to: 0)
  end

  @doc """
  Returns true if the money entity can be deleted (no transactions associated).
  """
  def delete_allowed?(money) do
    money = Ledger.Repo.preload(money, [:transactions_as_origin, :transactions_as_destination])
    Enum.empty?(money.transactions_as_origin) and Enum.empty?(money.transactions_as_destination)
  end
end
