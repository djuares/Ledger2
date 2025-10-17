defmodule Ledger.ListTransactions do
  import Ecto.Query
  alias Ledger.{Repo, Transaction}

  # Función principal: devuelve {:ok, string} con las transacciones filtradas
  def list(origin_account, destinate_account) do
    query =
      from t in Transaction,
        where:
          ^build_filters(origin_account, destinate_account),
          select: t

    with {:ok, transactions} <- fetch_transactions(query) do
      case transactions do
        [] ->
          {:error, transacciones: "No se encontraron transacciones para los filtros dados."}

        _ ->
          transactions = Repo.preload(transactions, [:origin_currency, :destination_currency, :origin_account, :destination_account])
          {:ok, transacciones: format_transactions(transactions)}
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

  # Construye filtros dinámicos según los valores recibidos
  def build_filters("0", "0"), do: dynamic([_t], true)
  def build_filters("0", dest), do: dynamic([t], t.destination_account_id == ^dest)
  def build_filters(orig, "0"), do: dynamic([t], t.origin_account_id == ^orig)
  def build_filters(orig, dest),
    do: dynamic([t], t.origin_account_id == ^orig and t.destination_account_id == ^dest)


  def format_transactions(transactions) do
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

    #
end

end
