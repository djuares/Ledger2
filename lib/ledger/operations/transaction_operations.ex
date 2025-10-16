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

  def can_undo?(transaction_id) do
    tx = Repo.get!(Transaction, transaction_id)

    last_for_origin =
      from(t in Transaction,
        where: t.origin_account_id == ^tx.origin_account_id,
        order_by: [desc: t.timestamp],
        limit: 1
      )
      |> Repo.one()

    last_for_destination =
      from(t in Transaction,
        where: t.destination_account_id == ^tx.destination_account_id,
        order_by: [desc: t.timestamp],
        limit: 1
      )
      |> Repo.one()

    tx.id == last_for_origin.id and tx.id == last_for_destination.id
  end

  def undo_transaction(transaction_id) do
    tx = Repo.get!(Transaction, transaction_id)

    if can_undo?(transaction_id) do
      attrs = %{
        timestamp: DateTime.utc_now(),
        amount: -tx.amount,
        type: "deshacer",
        origin_currency_id: tx.destination_currency_id,
        destination_currency_id: tx.origin_currency_id,
        origin_account_id: tx.destination_account_id,
        destination_account_id: tx.origin_account_id
      }

      %Transaction{}
      |> Transaction.changeset(attrs)
      |> Repo.insert()
    else
      {:error, :not_latest_transaction}
    end
  end

  def transfer(origin_account_id, destination_account_id, currency_id, amount) do
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
    {:ok, tx} -> {:ok, realizar_transferencia: "Transferencia realizada con ID #{tx.id}"}
    {:error, changeset} ->
      errors =
        changeset
          |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
          |> Enum.flat_map(fn {_field, messages} -> messages end)
          |> Enum.join("; ")
        {:error, realizar_transferencia: errors}
  end
end
def swap(user_id, origin_currency_id, destination_currency_id, amount) do
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
    {:ok, tx} -> {:ok, "Swap realizado con ID #{tx.id}"}
    {:error, changeset} -> {:error, changeset}
  end
end
def show_transaction(id) do
  case Repo.get(Transaction, id) do
    nil ->
      {:error, "Transacción con ID #{id} no encontrada"}

    tx ->
      {:ok,
       %{
         id: tx.id,
         type: tx.type,
         amount: tx.amount,
         origin_account_id: tx.origin_account_id,
         destination_account_id: tx.destination_account_id,
         origin_currency_id: tx.origin_currency_id,
         destination_currency_id: tx.destination_currency_id,
         timestamp: tx.timestamp
       }}
  end
end
end
