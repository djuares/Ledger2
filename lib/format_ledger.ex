defmodule Ledger.FormatLedger do

  def validate_line_format(line, line_number, existing_ids \\ MapSet.new()) do
    parts = String.split(line, ";")
    transaction_id = Enum.at(parts, 0)

    cond do
      length(parts) != 8 ->
        {:error, line_number}

      not is_valid_integer(Enum.at(parts, 0)) ->
        {:error, line_number}

      not is_valid_integer(Enum.at(parts, 1)) ->
        {:error, line_number}

      Enum.at(parts, 4) == "" or not is_valid_float(Enum.at(parts, 4)) ->
        {:error, line_number}

      Enum.at(parts, 7) not in ["transfer", "alta_cuenta", "swap"] ->
        {:error, line_number}

      MapSet.member?(existing_ids, transaction_id) ->
        {:error, line_number}

      true ->
        {:ok, transaction_id}  # Devuelve el ID válido
    end
  end


defp is_valid_integer(string) do
  case Integer.parse(string) do
    {_int, ""} -> true
    _ -> false
  end
end

defp is_valid_float(string) do
  case Float.parse(string) do
    {_float, ""} -> true
    _ -> false
  end
end
def format_balance(balance) when is_map(balance) do
  formatted =
    balance
    |> Enum.map(fn {currency, amount} ->
      "#{currency}=#{amount}"
    end)
    |> Enum.join("\n")

  {:ok, formatted}
end
end
