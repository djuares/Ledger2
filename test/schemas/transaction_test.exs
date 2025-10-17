defmodule Ledger.TransactionTest do
  use Ledger.RepoCase
  alias Ledger.{Transaction, Repo, Users, Money}

  describe "Transaction changeset" do
    setup do
      user1 = Repo.insert!(%Users{username: "juan", birth_date: ~D[2000-01-01]})
      user2 = Repo.insert!(%Users{username: "ana", birth_date: ~D[1995-05-05]})
      btc = Repo.insert!(%Money{name: "BTC", price: 50000.0})
      eth = Repo.insert!(%Money{name: "ETH", price: 3000.0})
      {:ok, users: [user1, user2], money: [btc, eth]}
    end

    test "valid transaction changeset", %{users: [user1, user2], money: [btc, eth]} do
      timestamp = DateTime.utc_now() |> DateTime.truncate(:second)

      attrs = %{
        timestamp: timestamp,
        origin_account_id: user1.id,
        destination_account_id: user2.id,
        origin_currency_id: btc.id,
        destination_currency_id: eth.id,
        amount: 100.0,
        type: "transfer"
      }

      changeset = Transaction.changeset(%Transaction{}, attrs)
      assert changeset.valid?
    end

    test "fails if origin account does not exist", %{money: [btc, eth]} do
      timestamp = DateTime.utc_now() |> DateTime.truncate(:second)

      attrs = %{
        timestamp: timestamp,
        origin_account_id: 999,
        destination_account_id: 1,
        origin_currency_id: btc.id,
        destination_currency_id: eth.id,
        amount: 50.0,
        type: "transfer"
      }

      changeset = Transaction.changeset(%Transaction{}, attrs)
      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :origin_account_id)
    end

    test "fails if destination account does not exist", %{users: [user1, _user2], money: [btc, eth]} do
      timestamp = DateTime.utc_now() |> DateTime.truncate(:second)

      attrs = %{
        timestamp: timestamp,
        origin_account_id: user1.id,
        destination_account_id: 999_999,
        origin_currency_id: btc.id,
        destination_currency_id: eth.id,
        amount: 100.0,
        type: "transfer"
      }

      changeset = Transaction.changeset(%Transaction{}, attrs)
      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :destination_account_id)
    end

    test "prevents duplicate alta_cuenta", %{users: [user1, _user2], money: [btc, _eth]} do
      timestamp = DateTime.utc_now() |> DateTime.truncate(:second)

      Repo.insert!(%Transaction{
        timestamp: timestamp,
        origin_account_id: user1.id,
        origin_currency_id: btc.id,
        amount: 100.0,
        type: "alta_cuenta"
      })

      attrs = %{
        timestamp: timestamp,
        origin_account_id: user1.id,
        origin_currency_id: btc.id,
        amount: 100.0,
        type: "alta_cuenta"
      }

      changeset = Transaction.changeset(%Transaction{}, attrs)
      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :type)
    end

    test "fails if amount is negative", %{users: [user1, user2], money: [btc, eth]} do
      timestamp = DateTime.utc_now() |> DateTime.truncate(:second)

      attrs = %{
        timestamp: timestamp,
        origin_account_id: user1.id,
        destination_account_id: user2.id,
        origin_currency_id: btc.id,
        destination_currency_id: eth.id,
        amount: -10.0,
        type: "transfer"
      }

      changeset = Transaction.changeset(%Transaction{}, attrs)
      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :amount)
    end

    test "allows destination_currency_id to be nil", %{users: [user1, user2], money: [btc, _eth]} do
      timestamp = DateTime.utc_now() |> DateTime.truncate(:second)

      attrs = %{
        timestamp: timestamp,
        origin_account_id: user1.id,
        destination_account_id: user2.id,
        origin_currency_id: btc.id,
        destination_currency_id: nil,
        amount: 50.0,
        type: "transfer"
      }

      changeset = Transaction.changeset(%Transaction{}, attrs)
      assert changeset.valid?
    end

    test "fails if origin currency does not exist", %{users: [user1, user2], money: [_btc, eth]} do
      timestamp = DateTime.utc_now() |> DateTime.truncate(:second)

      attrs = %{
        timestamp: timestamp,
        origin_account_id: user1.id,
        destination_account_id: user2.id,
        origin_currency_id: 999_999,
        destination_currency_id: eth.id,
        amount: 10.0,
        type: "transfer"
      }

      changeset = Transaction.changeset(%Transaction{}, attrs)
      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :origin_currency_id)
    end

    test "fails if destination currency does not exist", %{users: [user1, user2], money: [btc, _eth]} do
      timestamp = DateTime.utc_now() |> DateTime.truncate(:second)

      attrs = %{
        timestamp: timestamp,
        origin_account_id: user1.id,
        destination_account_id: user2.id,
        origin_currency_id: btc.id,
        destination_currency_id: 999_999,
        amount: 10.0,
        type: "transfer"
      }

      changeset = Transaction.changeset(%Transaction{}, attrs)
      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :destination_currency_id)
    end

    test "fails if timestamp is nil", %{users: [user1, user2], money: [btc, _eth]} do
      attrs = %{
        timestamp: nil,
        origin_account_id: user1.id,
        destination_account_id: user2.id,
        origin_currency_id: btc.id,
        destination_currency_id: nil,
        amount: 10.0,
        type: "transfer"
      }

      changeset = Transaction.changeset(%Transaction{}, attrs)
      refute changeset.valid?
      assert Keyword.has_key?(changeset.errors, :timestamp)
    end
  end
end
