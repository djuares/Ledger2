defmodule Ledger.ListTransactionsTest do
  use Ledger.RepoCase
  alias Ledger.{ListTransactions, Repo, Transaction, Money}

  import Ecto.Query

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
      usd = Repo.insert!(%Money{name: "USDS", price: 1.0})
      eur = Repo.insert!(%Money{name: "EURS", price: 1.1})

      # Creamos transacciones
      tx1 =
        Repo.insert!(%Transaction{
          origin_account_id: 1,
          destination_account_id: 2,
          origin_currency_id: usd.id,
          destination_currency_id: usd.id,
          amount: 100.0,
          type: "transfer",
          timestamp: DateTime.utc_now()|> DateTime.truncate(:second),
        })

      tx2 =
        Repo.insert!(%Transaction{
          origin_account_id: 2,
          destination_account_id: 1,
          origin_currency_id: eur.id,
          destination_currency_id: eur.id,
          amount: 50.0,
          type: "transfer",
          timestamp: DateTime.utc_now()|> DateTime.truncate(:second),
        })

      # Llamamos a la función filtrando por origen 1
      {:ok, result} = ListTransactions.list(1, "0")
      transacciones_str = result[:transacciones]

      # Verificamos que contenga tx1
      assert transacciones_str =~ Integer.to_string(tx1.id)
      assert transacciones_str =~ "USDS"

      # Verificamos que contenga tx2 si filtramos por destino 1
      {:ok, result2} = ListTransactions.list("0", 1)
      transacciones_str2 = result2[:transacciones]
      assert transacciones_str2 =~ Integer.to_string(tx2.id)
      assert transacciones_str2 =~ "EURS"
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
end
