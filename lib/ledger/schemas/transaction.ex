defmodule Ledger.Transaction do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias Ledger.{Repo, Users, Money, Transaction}

  schema "transactions" do
    field :timestamp, :utc_datetime
    belongs_to :origin_currency, Money
    belongs_to :destination_currency, Money
    field :amount, :float
    belongs_to :origin_account, Users
    belongs_to :destination_account, Users
    field :type, :string


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
  |> validate_required([:timestamp,:amount,:type,], message: "Dato incompleto")
  |> validate_accounts_exist()
  |> validate_money_exist()
  |> validate_number(:amount, greater_than_or_equal_to: 0, message: "El monto debe ser mayor o igual a 0")
  |> foreign_key_constraint(:origin_currency_id)
  |> foreign_key_constraint(:origin_account_id)
  |> validate_no_duplicate_alta_cuenta()
end

defp validate_no_duplicate_alta_cuenta(changeset) do
  type = get_change(changeset, :type)
  origin_account_id = get_change(changeset, :origin_account_id)
  origin_currency_id = get_change(changeset, :origin_currency_id)

  if type == "alta_cuenta" and origin_account_id && origin_currency_id do
    existing_query =
      from t in Transaction,
        where: t.origin_account_id == ^origin_account_id and
               t.origin_currency_id == ^origin_currency_id and
               t.type == "alta_cuenta",
        select: t.id

    case Repo.one(existing_query) do
      nil -> changeset
      _id -> add_error(changeset, :type, "Ya existe una transacción 'alta_cuenta' para esta cuenta y moneda")
    end
  else
    changeset
  end
end

  defp validate_accounts_exist(changeset) do
    origin_id = get_field(changeset, :origin_account_id)
    dest_id = get_field(changeset, :destination_account_id)

    cond do
      is_nil(origin_id) or not account_exists?(origin_id) ->
        add_error(changeset, :origin_account_id, "No existe un usuario para ese id")

      dest_id && not account_exists?(dest_id) ->
        add_error(changeset, :destination_account_id, "No existe un usuario para ese id")

      true ->
        changeset
    end
  end
  defp account_exists?(id), do: Repo.exists?(from u in Users, where: u.id == ^id)

  defp validate_money_exist(changeset) do
    origin_id = get_field(changeset, :origin_currency_id)
    dest_id = get_field(changeset, :destination_currency_id)

    cond do
      is_nil(origin_id) or not money_exists?(origin_id) ->
        add_error(changeset, :origin_currency_id, "No existe una moneda para ese id")

      dest_id && not money_exists?(dest_id) ->
        add_error(changeset, :destination_currency_id, "No existe una moneda para ese id")

      true ->
        changeset
    end
  end
  defp money_exists?(id), do: Repo.exists?(from u in Money, where: u.id == ^id)

end
