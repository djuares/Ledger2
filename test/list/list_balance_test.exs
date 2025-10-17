defmodule Ledger.ListBalanceTest do
  use Ledger.RepoCase, async: false

  alias Ledger.{ListBalance, Repo, Users, Money, Transaction}

  setup do
    # Asumimos que ya corriste seeds en la DB de test:
    sofia = Repo.get_by!(Users, username: "Sofía")
    mateo = Repo.get_by!(Users, username: "Mateo")

    btc = Repo.get_by!(Money, name: "BTC")
    eth = Repo.get_by!(Money, name: "ETH")
    ars = Repo.get_by!(Money, name: "ARS")
    usd = Repo.get_by!(Money, name: "USD")
    eur = Repo.get_by!(Money, name: "EUR")

    {:ok,
     users: %{sofia: sofia, mateo: mateo},
     money: %{btc: btc, eth: eth, ars: ars, usd: usd, eur: eur}}
  end

  describe "ListBalance.list/2" do
    test "retorna balance de Sofía", %{users: %{sofia: sofia}, money: %{btc: btc}} do
     {:ok, msg} = ListBalance.list(sofia.id, "0")
      balance_map =
        msg[:balance]
        |> String.split("\n")
        |> Enum.map(fn line ->
          [currency, amount] = String.split(line, "=")
          {currency, String.to_float(amount)}
        end)
        |> Map.new()

      # Ahora podés hacer asserts concretos
      assert balance_map["BTC"] == 0.5


    end

    test "retorna balance de Sofía en BTC", %{users: %{sofia: sofia}, money: %{btc: btc}} do
      {:ok, result} = ListBalance.list(sofia.id, btc.id)

      # El balance en BTC debe reflejar transacciones tipo alta_cuenta y transfer
      assert is_map(result[:balance])
      assert Map.has_key?(result[:balance], "BTC")
      assert result[:balance]["BTC"] > 0
    end

    test "retorna balance de Sofía en otra moneda (ETH)", %{users: %{sofia: sofia}, money: %{eth: eth}} do
      {:ok, result} = ListBalance.list(sofia.id, eth.id)

      assert is_map(result[:balance])
      assert Map.has_key?(result[:balance], "ETH")
      assert result[:balance]["ETH"] > 0
    end

    test "retorna error si usuario no tiene transacciones", %{users: %{mateo: mateo}} do
      # Creamos un usuario nuevo sin transacciones
      {:ok, new_user} =
        %Users{username: "Nuevo", birth_date: ~D[2005-01-01]} |> Repo.insert()

      {:error, result} = ListBalance.list(new_user.id, "0")
      assert result[:balance] =~ "No se encontraron transacciones"
    end

    test "balance total en USD", %{users: %{sofia: sofia}, money: %{usd: usd}} do
      {:ok, result} = ListBalance.list(sofia.id, usd.id)
      assert is_map(result[:balance])
      assert Map.has_key?(result[:balance], "USD")
      assert result[:balance]["USD"] > 0
    end
  end
end
