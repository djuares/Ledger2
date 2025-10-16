defmodule Ledger.ListBalance do
  import Ecto.Query
  alias Ledger.{Repo, Transaction, Conversion, Debit, Acredit}

  # Punto de entrada principal
  def list(origin_account, money_type) do
    with {:ok, transactions} <- fetch_transactions(origin_account),
        {:ok, total_balance} <- process_transactions(transactions, origin_account, money_type) do

      balance_str =
        total_balance
        |> Enum.map(fn {currency, amount} ->
          "#{currency}: #{amount}"
        end)
        |> Enum.join("\n")


      {:ok, balance: String.trim(balance_str)}
    else
      {:error, msg} ->
        {:error, balance: msg}
    end
  end





  # Consulta a la base de datos
  defp fetch_transactions(origin_account) do
    query =
      from t in Transaction,
        where: t.origin_account_id == ^origin_account or t.destination_account_id == ^origin_account,
        preload: [
          :origin_currency,
          :destination_currency,
          :origin_account,
          :destination_account
        ]
    try do
      {:ok, Repo.all(query)}
    rescue
      e in DBConnection.ConnectionError ->
        {:error, "Error en la base de datos: #{e.message}"}

      e ->
        {:error, "Error inesperado: #{inspect(e)}"}
    end
  end

  # Procesa las transacciones obtenidas
  defp process_transactions(transactions, origin_account, "0") do
  IO.inspect(transactions, label: ">>> Transacciones recibidas")

  {debits, credits} = categorize_transactions_fixed(transactions, origin_account)

  IO.inspect(debits, label: ">>> Lista 5 (debits)")
  IO.inspect(credits, label: ">>> Lista 6 (credits)")

  result2 = Debit.debit_balance(debits)
  IO.inspect(result2, label: ">>> Debits procesados (result2)")

  result = Acredit.acredit_balance(credits)
  IO.inspect(result, label: ">>> Credits procesados (result)")

  total_balance = combine_balances(result, result2)
  IO.inspect(total_balance, label: ">>> Balance total combinado")

  {:ok, total_balance}
end
defp process_transactions(transactions, origin_account, money_type) do
    case process_transactions(transactions, origin_account, "0") do
      {:ok, balance_map} ->
        case Conversion.convert_all_balances(balance_map, money_type) do
          {:ok, converted_balance} -> {:ok, converted_balance}
          {:error, message} -> {:error, message}
        end
      {:error, message} ->
        {:error, message}
    end
  end

defp categorize_transactions_fixed(transactions, account_id) do
  Enum.reduce(transactions, {[], []}, fn t, {debits, credits} ->
    cond do
      # DEBITS: Transferencias salientes donde soy el origin
      t.origin_account_id == account_id and t.type == "transfer" ->
        {[t | debits], credits}

      # CREDITS: Transferencias entrantes donde soy el destination
      t.destination_account_id == account_id and t.type == "transfer" ->
        {debits, [t | credits]}

      # CREDITS: Altas de cuenta y swaps donde soy el origin
      t.origin_account_id == account_id and t.type in ["alta_cuenta", "swap"] ->
        {debits, [t | credits]}

      # Caso por defecto - no incluir en ninguna lista
      true ->
        {debits, credits}
    end
  end)
  |> then(fn {d, c} -> {Enum.reverse(d), Enum.reverse(c)} end)
end


  defp combine_balances(acredit_balances, debit_balances) do
    Map.merge(acredit_balances, debit_balances, fn _currency, acredit_amount, debit_amount ->
      acredit_amount + debit_amount
    end)
  end
end
