defmodule Ledger.ListBalance do
  import Ecto.Query
  alias Ledger.{Repo, Transaction}

  # Función principal: devuelve {:ok, string} con las transacciones filtradas
def list(origin_account, money_type) do
  query =
    from t in Transaction,
      where: ^build_filters(origin_account, money_type),
      select: t

  with {:ok, transactions} <- fetch_transactions(query) do
    case transactions do
      [] ->
        {:error, balance: "No se encontraron transacciones para los filtros dados."}

      transactions ->
        transactions = Repo.preload(transactions, [:origin_currency, :destination_currency, :origin_account, :destination_account])

        {:ok, content} = format_transactions(transactions)
        money_type_name =
          if money_type == "0" do
            "0"
          else
            case Repo.get(Ledger.Money, money_type) do
              nil -> "0"  # fallback
              %Ledger.Money{name: name} -> name
            end
          end

        case process_content(content, origin_account, money_type_name) do
          {:ok, balance_map} ->
            balance_str = format_balance(balance_map)
            {:ok, balance: balance_str}

          {:error, message} ->
            {:error, balance: message}
        end
    end
  end
end

  # Función auxiliar para capturar errores de Repo.all
  def fetch_transactions(query) do
    try do
      {:ok, Repo.all(query)}
    rescue
      e in DBConnection.ConnectionError -> {:error, "Error en la base de datos: #{e.message}"}
      e -> {:error, "Error inesperado: #{inspect(e)}"}
    end
  end

  defp build_filters(origin_account, _money_type) do
    dynamic([t], t.origin_account_id == ^origin_account or t.destination_account_id == ^origin_account)
  end

  defp format_transactions(transactions) do
  try do
    formatted =
      transactions
      |> Enum.map(fn t ->
        "#{t.id};#{DateTime.to_unix(t.timestamp)};" <>
        "#{Map.get(t.origin_currency || %{}, :name, "")};" <>
        "#{Map.get(t.destination_currency || %{}, :name, "")};" <>
        "#{t.amount};" <>
        "#{t.origin_account_id};" <>
        "#{t.destination_account_id || ""};" <>
        "#{t.type}"
      end)
      |> Enum.join("\n")

    {:ok, formatted}
  rescue
    e ->
      {:error, "Error al formatear transacciones: #{inspect(e)}"}
  end
end
  def process_content(content, origin_account, "0") do
  lines = content
    |> String.split("\n")
    |> Enum.filter(&(&1 != ""))
    |> Enum.with_index(1)

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

  def combine_balances(acredit_balances, debit_balances) do
    Map.merge(acredit_balances, debit_balances, fn _currency, acredit_amount, debit_amount ->
      acredit_amount + debit_amount
    end)
end

  defp format_balance(balance_map) when is_map(balance_map) do
    balance_map
    |> Enum.map(fn {currency, amount} -> "#{currency}=#{amount}" end)
    |> Enum.join("\n")
  end

end
