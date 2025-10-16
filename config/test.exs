import Config
config :ledger, Ledger.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "ledger_test",
  hostname: "localhost",
  port: 5432,
  log: false
