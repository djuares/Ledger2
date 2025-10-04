defmodule TransactionsTest do
  use ExUnit.Case


  test "transacciones procesa contenido csv correctamente" do
    assert Ledger.Transactions.list("data/input/test.csv", "0", "0","data/output/default_output.csv") == {
              :ok,
              "1;1754937014;USDT;BTC;55000;133;122;transfer\n2;1754937024;BTC;USDT;1;122;555;transfer\n3;1754937034;BTC;ETH;2;555;122;transfer\n4;1754937054;BTC;BTC;0.1;555;122;transfer\n5;1754937044;BTC;USDT;0.1;122;;swap\n6;1754937074;ARS;;70000;122;;alta_cuenta\n7;1754937094;ARS;ETH;70000;122;555;transfer"
            }
  end
  test "transacciones procesa origin_account correctamente" do
    assert Ledger.Transactions.list("data/input/test.csv", "122", "0", "data/output/default_output.csv") == {
              :ok,
              "2;1754937024;BTC;USDT;1;122;555;transfer\n5;1754937044;BTC;USDT;0.1;122;;swap\n6;1754937074;ARS;;70000;122;;alta_cuenta\n7;1754937094;ARS;ETH;70000;122;555;transfer"
            }
  end
  test "transacciones procesa destine_account correctamente" do
    assert Ledger.Transactions.list("data/input/test.csv", "0", "122", "data/output/default_output.csv") == {
              :ok,
              "1;1754937014;USDT;BTC;55000;133;122;transfer\n3;1754937034;BTC;ETH;2;555;122;transfer\n4;1754937054;BTC;BTC;0.1;555;122;transfer"}
  end

  test "transacciones procesa origin_account and destine_account correctamente" do
    assert Ledger.Transactions.list("data/input/test.csv", "122", "555", "data/output/default_output.csv") == {
              :ok,
              "2;1754937024;BTC;USDT;1;122;555;transfer\n7;1754937094;ARS;ETH;70000;122;555;transfer"}
  end

  test "Transaction lista por cuenta coorectamente sin movimientos" do
    assert Ledger.Transactions.list("data/input/test.csv","999", "0","data/output/default_output.csv" ) ==  {:ok, ""}
  end

end
