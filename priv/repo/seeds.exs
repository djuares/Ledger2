# priv/repo/seeds.exs
alias Ledger.{Repo, Users, Money, Transaction}

# --- Usuarios ---
sofia = Repo.insert!(%Users{username: "Sofía",birth_date: ~D[2000-01-01]})
mateo = Repo.insert!(%Users{username: "Mateo", birth_date: ~D[2003-01-01]})
gustavo = Repo.insert!(%Users{username: "Gustavo", birth_date: ~D[1955-07-01]})
lucia = Repo.insert!(%Users{username: "Lucia",birth_date: ~D[1999-01-01]})

# --- Monedas ---
btc = Repo.insert!(%Money{name: "BTC", price: 55000.0})
eth = Repo.insert!(%Money{name: "ETH", price: 3000.0})
ars = Repo.insert!(%Money{name: "ARS", price: 0.0012})
usd = Repo.insert!(%Money{name: "USD", price: 1.0})
eur = Repo.insert!(%Money{name: "EUR", price: 1.18})

# --- Transacciones ---
Repo.insert!(%Transaction{
  timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
  amount: 55000.0,
  origin_currency_id: usd.id,
  destination_currency_id: btc.id,
  origin_account_id: sofia.id,
  destination_account_id: mateo.id,
  type: "transfer",
})
Repo.insert!(%Transaction{
  timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
  amount: 1.0,
  origin_currency_id: btc.id,
  destination_currency_id: usd.id,
  origin_account_id: sofia.id,
  destination_account_id: mateo.id,
  type: "transfer"
  })
Repo.insert!(%Transaction{
  timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
  amount: 2.0,
  origin_currency_id: btc.id,
  destination_currency_id: eth.id,
  origin_account_id: sofia.id,
  destination_account_id: mateo.id,
  type: "transfer",
  })
Repo.insert!(%Transaction{
  timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
  amount: 0.1,
  origin_currency_id: btc.id,
  destination_currency_id: btc.id,
  origin_account_id: sofia.id,
  destination_account_id: mateo.id,
  type: "transfer",
  })
Repo.insert!(%Transaction{
  timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
  amount: 0.1,
  origin_currency_id: btc.id,
  origin_account_id: sofia.id,
  type: "swap",
  })
Repo.insert!(%Transaction{
  timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
  amount: 7000.0,
  origin_currency_id: btc.id,
  origin_account_id: sofia.id,
  type: "alta_cuenta",
  })
Repo.insert!(%Transaction{
  timestamp: DateTime.utc_now() |> DateTime.truncate(:second),
  amount: 7000.0,
  origin_currency_id: ars.id,
  destination_currency_id: eth.id,
  origin_account_id: sofia.id,
  destination_account_id: mateo.id,
  type: "transfer",
  })
