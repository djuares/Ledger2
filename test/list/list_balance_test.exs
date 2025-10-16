defmodule Ledger.BalanceTest do
  use Ledger.RepoCase
  alias Ledger.{Repo, Transaction, ListBalance, Users, Money}

  setup do
    # Limpiar tablas
    Repo.delete_all(Transaction)
    Repo.delete_all(Users)
    Repo.delete_all(Money)

    # Crear usuarios
    user_122 = Repo.insert!(%Users{username: "User 122", birth_date: ~D[2000-01-01]})
    user_555 = Repo.insert!(%Users{username: "User 555", birth_date: ~D[2000-01-01]})
    user_133 = Repo.insert!(%Users{username: "User 133", birth_date: ~D[2000-01-01]})

    # Crear monedas
    btc  = Repo.insert!(%Money{name: "BTC",  price: 0.0})
    usdt = Repo.insert!(%Money{name: "USDT", price: 0.0})
    ars  = Repo.insert!(%Money{name: "ARS", price: 0.0})
    eth  = Repo.insert!(%Money{name: "ETH", price: 0.0})

    # Fecha fija
    ts = DateTime.from_naive!(~N[2024-01-01 00:00:00], "Etc/UTC")

    # Insertar transacciones
    Repo.insert!(%Transaction{
      timestamp: ts,
      amount: 55000.0,
      type: "transfer",
      origin_currency_id: usdt.id,
      destination_currency_id: btc.id,
      origin_account_id: user_133.id,
      destination_account_id: user_122.id
    })

    Repo.insert!(%Transaction{
      timestamp: ts,
      amount: 1.0,
      type: "transfer",
      origin_currency_id: btc.id,
      destination_currency_id: usdt.id,
      origin_account_id: user_122.id,
      destination_account_id: user_555.id
    })

    Repo.insert!(%Transaction{
      timestamp: ts,
      amount: 2.0,
      type: "transfer",
      origin_currency_id: btc.id,
      destination_currency_id: eth.id,
      origin_account_id: user_555.id,
      destination_account_id: user_122.id
    })

    Repo.insert!(%Transaction{
      timestamp: ts,
      amount: 0.1,
      type: "transfer",
      origin_currency_id: btc.id,
      destination_currency_id: btc.id,
      origin_account_id: user_555.id,
      destination_account_id: user_122.id
    })

    Repo.insert!(%Transaction{
      timestamp: ts,
      amount: 0.1,
      type: "swap",
      origin_currency_id: btc.id,
      destination_currency_id: usdt.id,
      origin_account_id: user_122.id,
      destination_account_id: nil
    })

    Repo.insert!(%Transaction{
      timestamp: ts,
      amount: 70000.0,
      type: "alta_cuenta",
      origin_currency_id: ars.id,
      destination_currency_id: nil,
      origin_account_id: user_122.id,
      destination_account_id: nil
    })

    Repo.insert!(%Transaction{
      timestamp: ts,
      amount: 70000.0,
      type: "transfer",
      origin_currency_id: ars.id,
      destination_currency_id: eth.id,
      origin_account_id: user_122.id,
      destination_account_id: user_555.id
    })

    {:ok,
     %{
       user_122: user_122,
       user_555: user_555,
       user_133: user_133,
       btc: btc,
       usdt: usdt,
       ars: ars,
       eth: eth
     }}
  end

  test "calcula balance por cuenta correctamente", %{user_122: user_122} do
    assert ListBalance.list(user_122.id, "0") ==  {:ok, %{"ARS" => 0.0, "BTC" => 0.0, "ETH" => 36.666667, "USDT" => 5500.0}}
  end

  test "calcula balance en tipo de moneda correctamente", %{user_122: user_122} do
    assert ListBalance.list(user_122.id, "BTC") == {:ok, %{"BTC" => 2.1}}
  end

  test "calcula balance para cuenta sin movimientos" do
    assert ListBalance.list(999, "0") ==
             {:error, "No se encontraron transacciones para la cuenta dada."}
  end
end
