defmodule Ledger.ListBalance do

def list(input_file, origin_account,  money_type, output_file) do
  case File.read(input_file) do
    {:ok, content} ->
      case process_content(content, origin_account, money_type) do
        {:error, message} ->
          {:error, message}
        {:ok, total_balance} ->
          case Ledger.FormatLedger.format_balance(total_balance) do
            {:ok, formatted_result} ->
              case File.write(output_file, formatted_result) do
                :ok ->
                  {:ok, formatted_result}
                {:error, reason} ->
                  {:error, "No se pudo escribir el archivo: #{reason}"}
              end

          end
      end
    {:error, reason} ->
      {:error, "No se pudo leer el archivo: #{reason}"}
  end
end

def process_content(content, origin_account, "0") do
  lines = content
    |> String.split("\n")
    |> Enum.filter(&(&1 != ""))
    |> Enum.with_index(1)

  # Cambiar la validación para usar MapSet y verificar IDs únicos
  validation_result = Enum.reduce_while(lines, {:ok, MapSet.new()}, fn {line, line_number}, {:ok, existing_ids} ->
    case Ledger.FormatLedger.validate_line_format(line, line_number, existing_ids) do
      {:ok, transaction_id} ->
        # Agregar el ID al conjunto y continuar
        new_ids = MapSet.put(existing_ids, transaction_id)
        {:cont, {:ok, new_ids}}

      {:error, message} ->
        {:halt, {:error, message}}
    end
  end)

  case validation_result do
    {:error, message} ->
      {:error, message}

    {:ok, _} ->
      {list_5, list_6} = Enum.reduce(lines, {[], []}, fn {line, _line_number}, {acc_5, acc_6} ->
        parts = String.split(line, ";")

        cond do
          Enum.at(parts, 5) == origin_account && Enum.at(parts, 7) == "transfer" ->
            {[line | acc_5], acc_6}
          Enum.at(parts, 6) == origin_account && Enum.at(parts, 7) == "transfer" ->
            {acc_5, [line | acc_6]}
          Enum.at(parts, 5) == origin_account && Enum.at(parts, 7) == "alta_cuenta" ->
            {acc_5, [line | acc_6]}
          Enum.at(parts, 5) == origin_account && Enum.at(parts, 7) == "swap" ->
            {acc_5, [line | acc_6]}
          Enum.at(parts, 6) == origin_account ->
            {acc_5, [line | acc_6]}
          true ->
            {acc_5, acc_6}
        end
      end)
      |> then(fn {l5, l6} -> {Enum.reverse(l5), Enum.reverse(l6)} end)

      result2 = Ledger.Debit.debit_balance(list_5)
      result = Ledger.Acredit.acredit_balance(list_6)
      total_balance = combine_balances(result, result2)
      {:ok, total_balance}
  end
end

def process_content(content, origin_account, money_type) do
  case process_content(content, origin_account, "0") do
    {:ok, balance_map} ->
      case Ledger.Conversion.convert_all_balances(balance_map, money_type) do
        {:ok, converted_balance} -> {:ok, converted_balance}
        {:error, message} -> {:error, message}
      end

    {:error, message} ->
      {:error, message}
  end
end

defp combine_balances(acredit_balances, debit_balances) do
  Map.merge(acredit_balances, debit_balances, fn _currency, acredit_amount, debit_amount ->
    acredit_amount + debit_amount
  end)
end

end
