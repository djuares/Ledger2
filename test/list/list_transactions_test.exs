defmodule Ledger.ListTransactionsTest do
  use Ledger.RepoCase
  alias Ledger.{ListTransactions, Repo, Transaction, Money, Users}

  setup do
    # Cada prueba obtiene una conexión aislada
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
  end

  describe "list/2" do
    test "retorna error si no hay transacciones" do
      # account_id ficticio
      origin_account = 999
      dest_account = 888

      assert {:error, transacciones: msg} = ListTransactions.list(origin_account, dest_account)
      assert msg =~ "No se encontraron transacciones"
    end

    test "retorna transacciones filtradas correctamente" do
      # Creamos monedas
      user1 = %Users{username: "Maria", birth_date: ~D[2000-01-01]} |> Repo.insert!()
      user2 = %Users{username: "Victoria", birth_date: ~D[2000-02-01]} |> Repo.insert!()

      usd = Repo.insert!(%Money{name: "USDS", price: 1.0})

      # Creamos transacciones
      tx1 =
        Repo.insert!(%Transaction{
          origin_account_id: user1.id,
          destination_account_id: user2.id,
          origin_currency_id: usd.id,
          destination_currency_id: usd.id,
          amount: 100.0,
          type: "transfer",
          timestamp: DateTime.utc_now()|> DateTime.truncate(:second),
        })

      # Llamamos a la función filtrando por origen 1
      {:ok, result} = ListTransactions.list(user1.id, "0")
      assert result[:transacciones] =~  "#{tx1.id};#{DateTime.to_unix(tx1.timestamp)};USDS;USDS;100.0;#{tx1.origin_account_id};#{tx1.destination_account_id};transfer"
    end

    test "build_filters genera filtros correctos" do
      # Probamos cada caso
      assert %Ecto.Query.DynamicExpr{} = ListTransactions.build_filters("0", "0")
      assert %Ecto.Query.DynamicExpr{} = ListTransactions.build_filters("0", 2)
      assert %Ecto.Query.DynamicExpr{} = ListTransactions.build_filters(1, "0")
      assert %Ecto.Query.DynamicExpr{} = ListTransactions.build_filters(1, 2)
    end
  end

  describe "format_transactions/1" do
    test "formatea correctamente las transacciones" do
      tx = %Transaction{
        id: 1,
        timestamp: DateTime.utc_now(),
        origin_currency: %{name: "USD"},
        destination_currency: %{name: "EUR"},
        amount: 100,
        origin_account_id: 1,
        destination_account_id: 2,
        type: "transfer"
      }

      formatted = ListTransactions.format_transactions([tx])
      assert formatted =~ "1;"
      assert formatted =~ "USD;"
      assert formatted =~ "EUR;"
      assert formatted =~ "100;"
      assert formatted =~ "transfer"
    end
  end
    test "handles DBConnection.ConnectionError" do
      query = :invalid_query

      # Como no hay conexión real, simulamos el rescue
      {:error, msg} = ListTransactions.fetch_transactions(query)
      assert String.contains?(msg, "Error con la base de datos")
    end
end
