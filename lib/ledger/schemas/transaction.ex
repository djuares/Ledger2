defmodule Ledger.Transaction do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ledger.{Users, Money}

  schema "transactions" do
    field :timestamp, :utc_datetime
    field :amount, :float
    field :type, :string

    belongs_to :origin_currency, Money
    belongs_to :destination_currency, Money
    belongs_to :origin_account, Users
    belongs_to :destination_account, Users

    timestamps()
  end

  def changeset(tx, attrs) do
    tx
    |> cast(attrs, [
      :timestamp,
      :amount,
      :type,
      :origin_currency_id,
      :destination_currency_id,
      :origin_account_id,
      :destination_account_id
    ])
    |> validate_required([
      :timestamp,
      :amount,
      :type,
      :origin_currency_id,
      :origin_account_id,
    ])
    |> foreign_key_constraint(:origin_currency_id)
    |> foreign_key_constraint(:origin_account_id)
  end
end
