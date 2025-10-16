defmodule Ledger.Debit do

  def debit_balance(transactions) do
    Enum.reduce(transactions, %{}, fn tx, acc ->
      # Obtener el nombre de la moneda de origen
      moneda_origen = tx.origin_currency.name
      monto = tx.amount

      # Actualizar el balance: los débitos son negativos
      Map.update(acc, moneda_origen, -monto, &(&1 - monto))
    end)
  end
end
