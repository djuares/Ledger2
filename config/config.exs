import Config

config :ledger, :ecto_repos, [Ledger.Repo]

config :ledger, Ledger.Repo,
  username: "postgres",
  password: "postgres",
  database: "ledger",
  hostname: "localhost",
  migration_lock: nil # this is not normally needed - we put it here to support an example of
                      # creating an index with the `concurrently` option set to true

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
