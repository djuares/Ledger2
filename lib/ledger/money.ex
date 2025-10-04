defmodule Ledger.Money do
  use Ecto.Schema
  import Ecto.Changeset

  schema "money" do
    field :transaction_id , :id, primary_key: true
    field :name, :string
    field :price_usd, :float
    field :created_at, :date
    field :updated_at, :date

    # Relation with transactions (origin or destination currency)
    has_many :origin_transactions, Ledger.Transaction, foreign_key: :origin_currency_id
    has_many :destination_transactions, Ledger.Transaction, foreign_key: :destination_currency_id
  end

  @spec changeset(
          {map(),
           %{
             optional(atom()) =>
               atom()
               | {:array | :assoc | :embed | :in | :map | :parameterized | :supertype | :try,
                  any()}
           }}
          | %{
              :__struct__ => atom() | %{:__changeset__ => any(), optional(any()) => any()},
              optional(atom()) => any()
            },
          :invalid | %{optional(:__struct__) => none(), optional(atom() | binary()) => any()}
        ) :: Ecto.Changeset.t()
  @doc """
  Validations for creating/updating currencies.
  """
  def changeset(currency, attrs) do
    currency
    |> cast(attrs, [:name, :price_usd, :created_at, :updated_at])
    |> validate_required([:name, :price_usd, :created_at, :updated_at])
    |> validate_length(:name, min: 3, max: 4)
    |> validate_format(:name, ~r/^[A-Z]+$/, message: "The name must be uppercase")
    |> unique_constraint(:name, message: "Currency name already exists")
    |> validate_number(:price_usd, greater_than_or_equal_to: 0, message: "Price cannot be negative")
  end

  @doc """
  Checks if the currency can be deleted (must not have associated transactions).
  """
  def delete_allowed?(%__MODULE__{origin_transactions: [], destination_transactions: []}), do: true
  def delete_allowed?(_), do: false
end
