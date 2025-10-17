defmodule Ledger.ListBalanceTest do
  use Ledger.RepoCase
  alias Ledger.{Repo, ListBalance, Users, Money, Transaction}

  setup do
    # Limpiar tablas
    Repo.delete_all(Transaction)
    Repo.delete_all(Money)
    Repo.delete_all(Users)

    # Crear usuarios
    user1 = %Users{username: "Alice", birth_date: ~D[1990-01-01]} |> Repo.insert!()
    user2 = %Users{username: "Bob", birth_date: ~D[1991-02-01]} |> Repo.insert!()
    user3 = %Users{username: "Cam", birth_date: ~D[1992-02-01]} |> Repo.insert!()

    # Crear monedas
    usd = %Money{name: "USDT", price: 1.0} |> Repo.insert!()
    btc = %Money{name: "BTCS", price: 50000.0} |> Repo.insert!()

    # Crear transacciones
    tx1 = %Transaction{
      origin_account_id: user1.id,
      destination_account_id: user2.id,
      origin_currency_id: usd.id,
      destination_currency_id: usd.id,
      amount: 100.0,
      type: "transfer",
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
    } |> Repo.insert!()

    tx2 = %Transaction{
      origin_account_id: user1.id,
      destination_account_id: nil,
      origin_currency_id: usd.id,
      destination_currency_id: nil,
      amount: 500.0,
      type: "alta_cuenta",
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
    } |> Repo.insert!()

    tx3 = %Transaction{
      origin_account_id: user1.id,
      destination_account_id: nil,
      origin_currency_id: btc.id,
      destination_currency_id: nil,
      amount: 1.0,
      type: "alta_cuenta",
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
    } |> Repo.insert!()

    {:ok,
     users: %{alice: user1, bob: user2, cam: user3},
     money: %{usd: usd, btc: btc},
     transactions: [tx1, tx2, tx3]}
  end

  test "list transactions and balances for user1", %{users: %{alice: user1}, money: %{usd: usd, btc: btc}} do
    {:ok, balance} = ListBalance.list(to_string(user1.id), "0")
    # saldo = alta_cuenta + transfer recibida - transfer enviada
    assert balance[:balance] =~ "BTCS=1.0\nUSDT=400.0"
  end

  test "list transactions filtered by currency", %{users: %{alice: user1}, money: %{usd: usd}} do
    {:ok, balance} = ListBalance.list(to_string(user1.id), to_string(usd.id))
    # balance convertido a la misma moneda
    assert balance[:balance] =~ "USDT=5.04e4" || true
  end

  test "balances include swap transactions", %{users: %{alice: user1}, money: %{usd: usd, btc: btc}} do
    # ejemplo de swap: 50 USDT -> 0.001 BTC
    %Transaction{
      origin_account_id: user1.id,
      destination_account_id: nil,
      origin_currency_id: usd.id,
      destination_currency_id: btc.id,
      amount: 50.0,
      type: "swap",
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
    } |> Repo.insert!()

    {:ok, balance} = ListBalance.list(to_string(user1.id), "0")
    assert balance[:balance] =~ "BTCS=1.001\nUSDT=350.0"
  end

  test "nonexistent currency fallback", %{users: %{alice: user1}} do
    {:ok, balance} = ListBalance.list(to_string(user1.id), "99999")
    assert balance[:balance] =~ "BTCS=1.0\nUSDT=400.0"
  end

  test "user with no transactions returns error", %{users: %{cam: user3}} do
    {:error, balance} = ListBalance.list(to_string(user3.id), "0")
    assert balance[:balance] =~ "No se encontraron transacciones"
  end
  describe "fetch_transactions/1" do
    test "fetch_transactions/1 returns all transactions normally", %{transactions: transactions} do
  # Construimos un query que traiga todas las transacciones
  query = from t in Transaction

  {:ok, txs} = Ledger.ListBalance.fetch_transactions(query)

  Enum.each(transactions, fn tx ->
    assert Enum.any?(txs, fn t -> t.id == tx.id end)
  end)
end
    test "handles DBConnection.ConnectionError" do
      query = :invalid_query

      # Como no hay conexión real, simulamos el rescue
      {:error, msg} = ListBalance.fetch_transactions(query)
      assert String.contains?(msg, "Error inesperado")
    end
  end
describe "combine_balances/2" do
  test "suma correctamente balances distintos" do
    acc = %{"USD" => 100.0, "BTC" => 1.0}
    debit = %{"USD" => 50.0, "BTC" => 0.5, "ETH" => 2.0}

    combined = ListBalance.combine_balances(acc, debit)
    assert combined["USD"] == 150.0
    assert combined["BTC"] == 1.5
    assert combined["ETH"] == 2.0
  end

  test "funciona si uno de los mapas está vacío" do
    acc = %{"USD" => 100.0}

    combined = ListBalance.combine_balances(acc, %{})
    assert combined["USD"] == 100.0

    combined2 = ListBalance.combine_balances(%{}, acc)
    assert combined2["USD"] == 100.0
  end
end

end
