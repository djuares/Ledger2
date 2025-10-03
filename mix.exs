defmodule Ledger.MixProject do
  use Mix.Project

  def project do
    [
      app: :ledger,
      version: "0.0.1",
      escript: escript_config(),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Ledger.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
defp deps do
  [
    {:ecto_sql, "~> 3.11"},
    {:postgrex, "~> 0.19"},
  ]
end

  defp escript_config do
    [
      main_module: Ledger.CLI
    ]
  end
end
