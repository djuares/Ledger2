defmodule Ledger.ListBalanceTest do
  use Ledger.RepoCase
  alias Ledger.{ListBalance, Repo, Transaction, MoneyOperations}

  describe "list/2" do
    setup do
      # Crear monedas usando MoneyOperations
      {:ok, _} = MoneyOperations.create_money("BTC", 55000)
      {:ok, _} = MoneyOperations.create_money("ETH", 3000)
      {:ok, _} = MoneyOperations.create_money("USDT", 1)

      btc = Repo.get_by(Ledger.Money, name: "BTC")
      eth = Repo.get_by(Ledger.Money, name: "ETH")
      usdt = Repo.get_by(Ledger.Money, name: "USDT")

      # Crear cuentas simuladas
      account1 = 1
      account2 = 2

      # Crear transacciones
      tx1 = Repo.insert!(%Transaction{
        origin_currency_id: btc.id,
        destination_currency_id: eth.id,
        amount: 1.5,
        origin_account_id: account1,
        destination_account_id: account2,
        type: "transfer",
        timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
      })

      tx2 = Repo.insert!(%Transaction{
        origin_currency_id: eth.id,
        destination_currency_id: btc.id,
        amount: 2.0,
        origin_account_id: account2,
        destination_account_id: account1,
        type: "swap",
        timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
      })

      {:ok, account1: account1, account2: account2, btc: btc, eth: eth, usdt: usdt}
    end

    test "returns balance map for money_type '0'", %{account1: account1} do
      {:ok, balance} = ListBalance.list(account1, "0")
      # balance[:balance] es un string de "MONEDA=amount\n..."
      assert balance[:balance] =~ "BTC="
      assert balance[:balance] =~ "ETH="
    end

    test "returns converted balance for another money_type", %{account1: account1} do
      {:ok, balance} = ListBalance.list(account1, "USDT")
      assert Map.has_key?(balance, "USDT")
      assert is_float(balance["USDT"])
    end

    test "returns error when no transactions", _context do
      {:error, msg} = ListBalance.list(999, "0")
      assert msg[:balance] =~ "No se encontraron transacciones"
    end

    test "handles conversion error gracefully", %{account1: account1} do
      # Forzar error en Conversion usando moneda inexistente
      {:error, msg} = ListBalance.list(account1, "NONEXISTENT")
      assert msg[:balance] =~ "Moneda NONEXISTENT no encontrada"
    end
  end
end
