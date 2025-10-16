defmodule Ledger.Acredit do

  def acredit_balance(transactions) do
    Enum.reduce(transactions, %{}, fn tx, acc ->
      moneda_origen = tx.origin_currency.name
      moneda_destino = if tx.destination_currency, do: tx.destination_currency.name, else: nil
      monto = tx.amount
      tipo_operacion = tx.type

      case tipo_operacion do
        "swap" ->
          # Swap: restar de origen, sumar a destino
          with {:ok, converted_amount} <- Ledger.Conversion.convert(moneda_origen, moneda_destino, monto) do
            acc
            |> Map.update(moneda_origen, -monto, &(&1 - monto))
            |> Map.update(moneda_destino, converted_amount, &(&1 + converted_amount))
          else
            _ -> acc
          end

        _ ->
          case moneda_destino do
            nil ->
              # Si no hay destino, solo sumar a la moneda origen
              Map.update(acc, moneda_origen, monto, &(&1 + monto))

            destino ->
              with {:ok, converted_amount} <- Ledger.Conversion.convert(moneda_origen, destino, monto) do
                Map.update(acc, destino, converted_amount, &(&1 + converted_amount))
              else
                _ -> acc
              end
          end
      end
    end)
  end
end
