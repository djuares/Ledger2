defmodule Ledger.Debit do

def debit_balance(debits) do
    Enum.reduce(debits, %{}, fn debit, acc ->
      [_, _, moneda_origen, _, monto_str, _, _, _] = String.split(debit, ";")
      {monto, _} = Float.parse(monto_str)
      Map.update(acc, moneda_origen, -monto, &(&1 - monto))
    end)
end
end
