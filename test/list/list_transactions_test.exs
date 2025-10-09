defmodule Ledger.ListTransactionsTest do
  use Ledger.RepoCase
  alias Ledger.{Repo, Transaction, Users, Money, ListTransactions}

  setup do
    # Usuarios
    user_122 = Repo.insert!(%Users{username: "User 122", birth_date: ~D[2000-01-01]})
    user_555 = Repo.insert!(%Users{username: "User 555", birth_date: ~D[2000-01-01]})
    user_133 = Repo.insert!(%Users{username: "User 133", birth_date: ~D[2000-01-01]})

    # Monedas
    btc  = Repo.insert!(%Money{name: "BTC",  price: 0.0})
    usdt = Repo.insert!(%Money{name: "USDT", price: 0.0})

    # Transacciones de prueba
    Repo.insert!(%Transaction{
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
      amount: 55000.0,
      type: "transfer",
      origin_currency_id: usdt.id,
      destination_currency_id: btc.id,
      origin_account_id: user_133.id,
      destination_account_id: user_122.id
    })

    Repo.insert!(%Transaction{
      timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
      amount: 1.0,
      type: "transfer",
      origin_currency_id: btc.id,
      destination_currency_id: usdt.id,
      origin_account_id: user_122.id,
      destination_account_id: user_555.id
    })


    {:ok, %{user_122: user_122, user_555: user_555, user_133: user_133}}
  end

  test "devuelve todas las transacciones cuando no hay filtros", %{user_122: user_122, user_555: user_555, user_133: user_133} do
    {:ok, transactions_csv} = ListTransactions.list("0", "0")

    # Verificamos que aparezcan los montos de ambas transacciones
      assert String.contains?(transactions_csv, "5.5e4")
      assert String.contains?(transactions_csv, "1.0")

    # Verificamos que aparezcan los IDs de los usuarios
    assert String.contains?(transactions_csv, "#{user_122.id}")
    assert String.contains?(transactions_csv, "#{user_555.id}")
    assert String.contains?(transactions_csv, "#{user_133.id}")
  end

  test "filtra correctamente por origin_account", %{user_122: user_122, user_555: user_555, user_133: user_133} do
    {:ok, transactions_csv} = ListTransactions.list("#{user_122.id}", "0")

    # Debe contener la transacción donde user_122 es origen
    assert transactions_csv =~ "#{user_122.id};#{user_555.id}"

    # No debe contener la transacción donde user_133 es origen
    refute transactions_csv =~ "#{user_133.id};#{user_122.id}"
  end

  test "filtra correctamente por destination_account", %{user_122: user_122, user_555: user_555, user_133: user_133} do
    {:ok, transactions_csv} = ListTransactions.list("0", "#{user_122.id}")

    # Debe contener la transacción donde user_122 es destino
    assert transactions_csv =~ "#{user_133.id};#{user_122.id}"

    # No debe contener la transacción donde user_122 no es destino
    refute transactions_csv =~ "#{user_122.id};#{user_555.id}"
  end

  test "devuelve error cuando no hay movimientos" do
    {:error, msg} = ListTransactions.list("999", "0")
    assert msg == "No se encontraron transacciones para los filtros dados."
  end
end
