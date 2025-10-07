defmodule BalanceTest do
  use ExUnit.Case

  @content "1;1754937014;USDT;BTC;55000;133;122;transfer
2;1754937024;BTC;USDT;1;122;555;transfer
3;1754937034;BTC;ETH;2;555;122;transfer
4;1754937054;BTC;BTC;0.1;555;122;transfer
5;1754937044;BTC;USDT;0.1;122;;swap
6;1754937074;ARS;;70000;122;;alta_cuenta
7;1754937094;ARS;ETH;70000;122;555;transfer"

  test "Balance calcula balance por cuenta correctamente" do
    expected = {:ok, %{"ARS" => 0.0, "BTC" => 0.0, "ETH" => 36.666667, "USDT" => 5500.0}}
    assert Ledger.ListBalance.process_content(@content, "122", "0") == expected
  end

  test "Balance calcula balance por cuenta en tipo de moneda correctamente" do
    assert Ledger.ListBalance.process_content(@content, "122", "BTC") ==   {:ok, %{"BTC" => 2.1}}
  end
  test "Balance calcula balance corectamente para cuenta sin movimientos" do
    assert Ledger.ListBalance.process_content(@content,"999", "0") ==  {:ok, %{}}
  end
  test "Balance calcula balance en moneda corectamente para cuenta sin movimientos" do
    assert Ledger.ListBalance.process_content(@content, "999", "BTC") ==  {:ok, %{"BTC" => 0.0}}
  end
  test "No se calcula balance para archivo csv que no cumple el formato" do
    corrupt_content = "1754937004;BTC;USDT;no_es_numero;122;555;transfer"
    assert Ledger.ListBalance.process_content(corrupt_content, "122", "0") == {:error, 1}
  end
end
