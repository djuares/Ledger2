defmodule Ledger.TransactionOperations do
  import Ecto.Query
  alias Ledger.{Repo, Transaction}

  def create_high_account(origin_account_id, origin_currency_id, amount) do
        attrs = %{
          type: "alta_cuenta",
          amount: amount,
          origin_account_id: origin_account_id,
          origin_currency_id: origin_currency_id,
          timestamp: DateTime.utc_now()
        }

        %Transaction{}
        |> Transaction.changeset(attrs)
        |> Repo.insert()
        |> case do
          {:ok, transaction} ->
            {:ok, alta_cuenta: "Transacción realizada correctamente con ID #{transaction.id}"}

          {:error, changeset} ->
            message =
              changeset
              |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
              |> Enum.flat_map(fn {_field, msgs} -> msgs end)
              |> Enum.join("; ")

            {:error, alta_cuenta: message}
      end
  end
 def transfer(origin_account_id, destination_account_id, currency_id, amount) do
  amount =
    cond do
      is_binary(amount) ->
        case Float.parse(amount) do
          {val, _} -> val
          :error -> raise ArgumentError, "Monto inválido: #{inspect(amount)}"
        end

      is_number(amount) -> amount
      true -> raise ArgumentError, "Monto inválido: #{inspect(amount)}"
    end

  cond do
    amount <= 0 ->
      {:error, realizar_transferencia: "El monto a transferir debe ser mayor que cero."}

    not cuentas_dadas_de_alta?(origin_account_id, destination_account_id) ->
      {:error, realizar_transferencia: "Ambas cuentas deben tener una transacción de tipo 'alta_cuenta' antes de transferir."}

    true ->
      case Ledger.ListBalance.list(origin_account_id, "0") do
        {:ok, balance: balance_str} ->
          balance_map = parse_balance_string(balance_str)

          case saldo_suficiente?(balance_map, currency_id, amount) do
            true ->
              realizar_transferencia(origin_account_id, destination_account_id, currency_id, amount)

            false ->
              {:error, realizar_transferencia: "Saldo insuficiente para realizar la transferencia con esa moneda."}
          end

        {:error, balance: msg} ->
          {:error, realizar_transferencia: "No se pudo obtener el balance: #{msg}"}
      end
  end
end

defp realizar_transferencia(origin_account_id, destination_account_id, currency_id, amount) do
  attrs = %{
    type: "transfer",
    amount: amount,
    origin_account_id: origin_account_id,
    destination_account_id: destination_account_id,
    origin_currency_id: currency_id,
    destination_currency_id: currency_id,
    timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
  }

  %Transaction{}
  |> Transaction.changeset(attrs)
  |> Repo.insert()
  |> case do
    {:ok, tx} ->
      {:ok, realizar_transferencia: "Transferencia realizada con ID #{tx.id}"}

    {:error, changeset} ->
      errors =
        changeset
        |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
        |> Enum.flat_map(fn {_field, messages} -> messages end)
        |> Enum.join("; ")

      {:error, realizar_transferencia: errors}
  end
end

defp cuentas_dadas_de_alta?(origin_account_id, destination_account_id) do
  origen_alta? =
    Repo.exists?(
      from t in Transaction,
        where:
          (t.origin_account_id == ^origin_account_id or t.destination_account_id == ^origin_account_id) and
            t.type == "alta_cuenta"
    )

  destino_alta? =
    Repo.exists?(
      from t in Transaction,
        where:
          (t.origin_account_id == ^destination_account_id or t.destination_account_id == ^destination_account_id) and
            t.type == "alta_cuenta"
    )

  origen_alta? and destino_alta?
end

defp parse_balance_string(balance_str) do
  balance_str
  |> String.split("\n", trim: true)
  |> Enum.map(fn line ->
    [currency, amount] = String.split(line, "=")
    {currency, String.to_float(amount)}
  end)
  |> Enum.into(%{})
end

defp saldo_suficiente?(balance_map, currency_id, amount) do
  case Ledger.Repo.get(Ledger.Money, currency_id) do
    nil ->
      IO.puts("❌ No se encontró la moneda con ID #{currency_id} en la base de datos")
      false

    money ->
      current_balance = Map.get(balance_map, money.name, 0.0)
      current_balance >= amount
  end
end


def swap(user_id, origin_currency_id, destination_currency_id, amount) do
  amount =
    cond do
      is_binary(amount) ->
        case Float.parse(amount) do
          {val, _} -> val
          :error -> raise ArgumentError, "Monto inválido: #{inspect(amount)}"
        end

      is_number(amount) -> amount
      true -> raise ArgumentError, "Monto inválido: #{inspect(amount)}"
    end
  cond do
    amount <= 0 ->
      {:error, realizar_swap: "El monto a intercambiar debe ser mayor que cero."}

    not cuentas_dadas_de_alta?(user_id, user_id) ->
      {:error,realizar_swap: "La cuenta debe tener una transacción de tipo 'alta_cuenta' antes de hacer swap."}

    true ->
      case Ledger.ListBalance.list(user_id, "0") do
        {:ok, balance: balance_str} ->
          balance_map = parse_balance_string(balance_str)

          if not saldo_suficiente?(balance_map, origin_currency_id, amount) do
            {:error, realizar_swap: "Saldo insuficiente para realizar el swap con la moneda de origen."}
          else
            attrs = %{
              type: "swap",
              amount: amount,
              origin_account_id: user_id,
              destination_account_id: user_id,
              origin_currency_id: origin_currency_id,
              destination_currency_id: destination_currency_id,
              timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
            }

            %Transaction{}
            |> Transaction.changeset(attrs)
            |> Repo.insert()
            |> case do
              {:ok, tx} -> {:ok, realizar_swap: "Swap realizado con ID #{tx.id}"}
              {:error, changeset} ->
                errors =
                  changeset
                  |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
                  |> Enum.flat_map(fn {_field, messages} -> messages end)
                  |> Enum.join("; ")

                {:error, realizar_swap: errors}
            end
          end

        {:error, balance: msg} ->
          {:error, "No se pudo obtener el balance: #{msg}"}
      end
    end
  end

def undo_transaction(transaction_id) do
  case Repo.get(Transaction, transaction_id) do
    nil ->
      {:error, undo: "Transacción no encontrada"}

    %Transaction{type: type} = tx ->
      if can_undo?(tx) do
        case type do
          "transfer" ->
            undo_transfer(tx)

          "swap" ->
            undo_swap(tx)

          "alta_cuenta" ->
            if has_later_transactions?(tx) do
              {:error, undo: "No se puede deshacer la alta de cuenta: hay transacciones posteriores"}
            else
              undo_high_account(tx)
            end

          _ ->
            {:error, undo: "Tipo de transacción no soportado para deshacer"}
        end
      else
        {:error, undo: "Solo se puede deshacer la última transacción de la cuenta"}
      end
  end
end
defp has_later_transactions?(%Transaction{} = tx) do
  count =
    from(t in Transaction,
      where:
        t.origin_account_id == ^tx.origin_account_id and
          t.timestamp > ^tx.timestamp
    )
    |> Repo.aggregate(:count)

  count > 0
end
defp undo_high_account(%Transaction{id: id} = tx) do
  Repo.delete(tx)
  {:ok, undo: "Alta de cuenta deshecha correctamente"}
end


  defp can_undo?(%Transaction{} = tx) do
    last_for_origin =
      from(t in Transaction,
        where: t.origin_account_id == ^tx.origin_account_id,
        order_by: [desc: t.timestamp],
        limit: 1
      )
      |> Repo.one()

    last_for_destination =
      if tx.destination_account_id do
        from(t in Transaction,
          where: t.destination_account_id == ^tx.destination_account_id,
          order_by: [desc: t.timestamp],
          limit: 1
        )
        |> Repo.one()
      else
        tx
      end

    tx.id == last_for_origin.id and tx.id == last_for_destination.id
  end

  defp undo_transfer(%Transaction{} = tx) do

  destination_str = to_string(tx.destination_account_id)
  origin_str = to_string(tx.origin_account_id)
  currency_str = to_string(tx.origin_currency_id)
  amount_str = Float.to_string(tx.amount)

  transfer(destination_str, origin_str, currency_str, amount_str)
end

  defp undo_swap(%Transaction{} = tx) do
    origin_str = to_string(tx.origin_account_id)
    dest_currency_str = to_string(tx.destination_currency_id)
    origin_currency_str = to_string(tx.origin_currency_id)
    amount_str = Float.to_string(tx.amount)

    swap(origin_str, dest_currency_str, origin_currency_str, amount_str)
end



  def show_transaction(id) do
    case Repo.get(Transaction, id) do
      nil ->
        {:error, view_transaction: "Transacción con ID #{id} no encontrada"}

      transaction ->
        transaction_str = """
        id= #{transaction.id}
        timestamp: #{DateTime.to_string(transaction.timestamp)}
        origin_currency_id: #{transaction.origin_currency_id}
        destination_currency_id: #{transaction.destination_currency_id}
        amount: #{transaction.amount}
        origin_account_id: #{transaction.origin_account_id}
        destination_account_id: #{transaction.destination_account_id}
        type: #{transaction.type}
        """
        {:ok, view_transaction: String.trim(transaction_str)}
    end
end
end
