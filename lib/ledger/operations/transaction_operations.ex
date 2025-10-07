defmodule Ledger.TransactionOperations do
  alias Ledger.{Repo, Transaction}

  def create_high_account(origin_account_id, origin_currency_id) do
    attrs = %{
      type: "high_account",
      amount: 0.0,
      origin_account_id: origin_account_id,
      origin_currency_id: origin_currency_id,
      timestamp: DateTime.utc_now()
    }

    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        {:ok, "Transactions made successfully with ID #{user.id}"}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
