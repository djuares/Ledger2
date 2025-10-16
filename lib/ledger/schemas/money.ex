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
  |> validate_required([:name, :price], message: "dato incompleto")
  |> update_change(:name, &String.upcase/1)
  |> unique_constraint(:name, message: "Ya existe una moneda con ese nombre")
  |> validate_number(:price, greater_than_or_equal_to: 0, message: "El precio debe ser mayor o igual a 0")
  |> validate_name_length()
end

  defp validate_name_length(changeset) do
  case get_change(changeset, :name) do
    nil ->
      changeset
    name ->
      if String.length(name) < 3 or String.length(name) > 4 do
        add_error(changeset, :name, "insertar una longitud valida")
      else
        changeset
      end
  end
end

end
