import Config

if config_env() == :dev do
  config :ledger, Ledger.Repo,
    database: System.get_env("POSTGRES_DB", "ledger"),
    username: System.get_env("POSTGRES_USER", "postgres"),
    password: System.get_env("POSTGRES_PASSWORD", "postgres"),
    hostname: System.get_env("POSTGRES_HOST", "localhost"),
    port: String.to_integer(System.get_env("POSTGRES_PORT", "5432"))
end
