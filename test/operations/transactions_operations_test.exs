defmodule Ledger.TransactionOperationsTest do
  use Ledger.RepoCase
  alias Ledger.{TransactionOperations, Transaction, Repo, Users, Money}

  describe "create_high_account/2" do
    setup do
      {:ok, user} =
        %Users{}
        |> Users.create_changeset(%{username: "sofia", birth_date: ~D[2000-01-01]})
        |> Repo.insert()

      {:ok, currency} =
        %Money{}
        |> Money.changeset(%{name: "USD", price: 1.0})
        |> Repo.insert()

      %{user: user, currency: currency}
    end

    test "inserts a high_account transaction", %{user: user, currency: currency} do
      {:ok, msg} = TransactionOperations.create_high_account(user.id, currency.id, "600")
      assert msg =~ "Transactions made successfully with ID"

      [id_str] = Regex.run(~r/ID (\d+)/, msg, capture: :all_but_first)
      tx_id = String.to_integer(id_str)

      tx_from_db = Repo.get!(Transaction, tx_id)
      assert tx_from_db.type == "high_account"
      assert tx_from_db.amount == 600
      assert tx_from_db.origin_account_id == user.id
      assert tx_from_db.origin_currency_id == currency.id
    end
  end

  describe "undo_transaction/1" do
    setup do
      {:ok, origin_user} =
        %Users{}
        |> Users.create_changeset(%{username: "sofia", birth_date: ~D[2000-01-01]})
        |> Repo.insert()

      {:ok, dest_user} =
        %Users{}
        |> Users.create_changeset(%{username: "mateo", birth_date: ~D[2001-01-01]})
        |> Repo.insert()

      {:ok, currency} =
        %Money{}
        |> Money.changeset(%{name: "USD", price: 1.0})
        |> Repo.insert()

      {:ok, tx} =
        %Transaction{}
        |> Transaction.changeset(%{
          timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
          amount: 10.0,
          type: "transfer",
          origin_currency_id: currency.id,
          destination_currency_id: currency.id,
          origin_account_id: origin_user.id,
          destination_account_id: dest_user.id
        })
        |> Repo.insert()

      %{tx: tx, origin_user: origin_user, dest_user: dest_user, currency: currency}
    end

    test "solo puede deshacerse la última transacción", %{tx: tx, origin_user: origin_user, dest_user: dest_user, currency: currency} do
      assert TransactionOperations.can_undo?(tx.id)

      {:ok, _} =
        %Transaction{}
        |> Transaction.changeset(%{
          timestamp: DateTime.add(DateTime.utc_now(), 10) |> DateTime.truncate(:second),
          amount: 5.0,
          type: "transfer",
          origin_currency_id: currency.id,
          destination_currency_id: currency.id,
          origin_account_id: origin_user.id,
          destination_account_id: dest_user.id
        })
        |> Repo.insert()

      refute TransactionOperations.can_undo?(tx.id)
    end

    test "undo_transaction crea una transacción inversa", %{tx: tx} do
      {:ok, reversed} = TransactionOperations.undo_transaction(tx.id)

      assert reversed.amount == -tx.amount
      assert reversed.origin_account_id == tx.destination_account_id
      assert reversed.destination_account_id == tx.origin_account_id
      assert reversed.type == "reversal"
    end
  end

  describe "transfer/4" do
    setup do
      {:ok, origin_user} =
        %Users{}
        |> Users.create_changeset(%{username: "Alice", birth_date: ~D[1990-01-01]})
        |> Repo.insert()

      {:ok, dest_user} =
        %Users{}
        |> Users.create_changeset(%{username: "Bob", birth_date: ~D[1992-01-01]})
        |> Repo.insert()

      {:ok, currency} =
        %Money{}
        |> Money.changeset(%{name: "USD", price: 1.0})
        |> Repo.insert()

      %{origin_user: origin_user, dest_user: dest_user, currency: currency}
    end

    test "realiza una transferencia entre usuarios", %{origin_user: origin_user, dest_user: dest_user, currency: currency} do
      {:ok, msg} = TransactionOperations.transfer(origin_user.id, dest_user.id, currency.id, 50.0)
      assert msg =~ "Transferencia realizada con ID"
    end
  end

  describe "swap/4" do
    setup do
      {:ok, user} =
        %Users{}
        |> Users.create_changeset(%{username: "sofia", birth_date: ~D[2000-01-01]})
        |> Repo.insert()

      {:ok, currency1} =
        %Money{}
        |> Money.changeset(%{name: "USD", price: 1.0})
        |> Repo.insert()

      {:ok, currency2} =
        %Money{}
        |> Money.changeset(%{name: "EUR", price: 0.9})
        |> Repo.insert()

      %{user: user, origin_currency: currency1, destination_currency: currency2}
    end

    test "creates a swap transaction", %{user: user, origin_currency: c1, destination_currency: c2} do
      {:ok, msg} = TransactionOperations.swap(user.id, c1.id, c2.id, 50.0)
      assert msg =~ "Swap realizado con ID"

      [id_str] = Regex.run(~r/ID (\d+)/, msg, capture: :all_but_first)
      tx_id = String.to_integer(id_str)

      tx = Repo.get!(Transaction, tx_id)
      assert tx.type == "swap"
      assert tx.amount == 50.0
      assert tx.origin_account_id == user.id
      assert tx.destination_account_id == user.id
      assert tx.origin_currency_id == c1.id
      assert tx.destination_currency_id == c2.id
    end
  end

  describe "show_transaction/1" do
    setup do
      {:ok, user} =
        %Users{}
        |> Users.create_changeset(%{username: "sofia", birth_date: ~D[2000-01-01]})
        |> Repo.insert()

      {:ok, currency} =
        %Money{}
        |> Money.changeset(%{name: "USD", price: 1.0})
        |> Repo.insert()

      {:ok, tx} =
        %Transaction{}
        |> Transaction.changeset(%{
          timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
          amount: 10.0,
          type: "transfer",
          origin_account_id: user.id,
          destination_account_id: user.id,
          origin_currency_id: currency.id,
          destination_currency_id: currency.id
        })
        |> Repo.insert()

      %{tx: tx}
    end

    test "returns transaction details", %{tx: tx} do
      {:ok, data} = TransactionOperations.show_transaction(tx.id)
      assert data.id == tx.id
      assert data.type == tx.type
      assert data.amount == tx.amount
    end
  end
end
