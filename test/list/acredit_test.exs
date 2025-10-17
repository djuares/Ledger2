defmodule Ledger.AcreditTest do
  use Ledger.RepoCase
  alias Ledger.{Acredit, Money}

  describe "acredit_balance/1" do
    setup do
      btc = Repo.insert!(%Money{name: "BTC", price: 55000.0})
      eth = Repo.insert!(%Money{name: "ETH", price: 3000.0})
      {:ok,  money: [btc, eth]}
    end

    test "acredita saldo normal sin destino" do
      accs = [
        "1;2;BTC;;100;;;alta_cuenta"
      ]

      result = Acredit.acredit_balance(accs)

      # Como no hay moneda destino, BTC simplemente aumenta 100
      assert result == %{"BTC" => 100.0}
    end

    test "acredita saldo con destino" do
      accs = ["1;2;BTC;ETH;10;;;transfer"]

      result = Acredit.acredit_balance(accs)
      # BTC se convierte a ETH
      assert result == %{"ETH" => 183.333333}
    end

    test "acredita saldo con swap" do
      accs = ["1;2;BTC;ETH;10;;;swap"]

      result = Acredit.acredit_balance(accs)
      # BTC disminuye, ETH aumenta según conversion
      assert result ==%{"BTC" => -10.0, "ETH" => 183.333333}
    end

    test "acredita varias operaciones acumulando saldo" do
      accs = [
        "1;2;BTC;;50;;;alta_cuenta",
        "1;2;ETH;;10;;;alta_cuenta"
      ]

      result = Acredit.acredit_balance(accs)
      assert result == %{"BTC" => 50.0, "ETH" => 10.0}
    end

    test "ignora conversion fallida" do
      accs = ["1;2;DOGE;ETH;10;;;transfer"]

      result = Acredit.acredit_balance(accs)
      assert result == %{}  # No se suma nada porque conversion falla
    end
    test "acredita saldo con varias operaciones combinadas" do
      accs = [
        "1;2;BTC;;100;;;alta_cuenta",
        "2;3;ETH;BTC;50;;;transfer",
        "3;4;BTC;ETH;10;;;swap"
      ]
      result = Acredit.acredit_balance(accs)
      assert result ==  %{"BTC" => 92.727273, "ETH" => 183.333333}
    end
    test "acredit_balance con lista vacía" do
      assert Acredit.acredit_balance([]) == %{}
    end

    test "acredit_balance con tipo de operacion desconocido" do
      accs = ["1;2;BTC;;100;;;unknown"]
      result = Acredit.acredit_balance(accs)
      assert result == %{"BTC" => 100.0}
    end

    end

  end

