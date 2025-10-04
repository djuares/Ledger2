defmodule Ledger.Acredit do

def acredit_balance(accreditations) do
  Enum.reduce(accreditations, %{}, fn accreditation, acc ->
    [_, _, moneda_origen, moneda_destino, monto_str, _, _, tipo_operacion] = String.split(accreditation, ";")
    {monto, _} = Float.parse(monto_str)

    case tipo_operacion do
      "swap" ->
        with {:ok, converted_amount} <- Ledger.Conversion.convert(moneda_origen, moneda_destino, monto) do
          acc
          |> Map.update(moneda_origen, -monto, &(&1 - monto))  # Restar de moneda origen
          |> Map.update(moneda_destino, converted_amount, &(&1 + converted_amount))  # Sumar a moneda destino
        else
          _ -> acc
        end

      _ ->
        case moneda_destino do
          "" ->
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
