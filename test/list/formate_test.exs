defmodule FormatTest do
  use ExUnit.Case

  describe "validate_line_format" do
    test "línea válida devuelve :ok" do
      valid_line = "1;1754937004;BTC;USDT;1.5;122;555;transfer"
      assert {:ok, "1"} = Ledger.FormatLedger.validate_line_format(valid_line, 1)
    end

    test "error cuando número de campos incorrecto" do
      # Falta un campo
      invalid_line = "1;1754937004;BTC;USDT;1.5;122;555"
      assert {:error, 1} = Ledger.FormatLedger.validate_line_format(invalid_line, 1)
    end

    test "error cuando ID no es entero válido" do
      invalid_line = "abc;1754937004;BTC;USDT;1.5;122;555;transfer"
      assert {:error, 1} = Ledger.FormatLedger.validate_line_format(invalid_line, 1)
    end

    test "error cuando timestamp no es entero válido" do
      invalid_line = "1;not_timestamp;BTC;USDT;1.5;122;555;transfer"
      assert {:error, 1} = Ledger.FormatLedger.validate_line_format(invalid_line, 1)
    end

    test "error cuando monto no es float válido" do
      invalid_line = "1;1754937004;BTC;USDT;not_number;122;555;transfer"
      assert {:error, 1} = Ledger.FormatLedger.validate_line_format(invalid_line, 1)
    end

    test "error cuando monto está vacío" do
      invalid_line = "1;1754937004;BTC;USDT;;122;555;transfer"
      assert {:error, 1} = Ledger.FormatLedger.validate_line_format(invalid_line, 1)
    end

    test "error cuando tipo de operación no es válido" do
      invalid_line = "1;1754937004;BTC;USDT;1.5;122;555;invalid_type"
      assert {:error, 1} = Ledger.FormatLedger.validate_line_format(invalid_line, 1)
    end

    test "operaciones válidas: transfer, alta_cuenta, swap" do
      valid_transfer = "1;1754937004;BTC;USDT;1.5;122;555;transfer"
      valid_alta = "1;1754937004;BTC;USDT;1.5;122;555;alta_cuenta"
      valid_swap = "1;1754937004;BTC;USDT;1.5;122;555;swap"

      assert  {:ok, "1"} = Ledger.FormatLedger.validate_line_format(valid_transfer, 1)
      assert {:ok, "1"} = Ledger.FormatLedger.validate_line_format(valid_alta, 2)
      assert  {:ok, "1"} = Ledger.FormatLedger.validate_line_format(valid_swap, 3)

    end

    test "procesa contenido con IDs únicos correctamente" do
      content = """
      123;1754937004;BTC;USDT;1.5;122;555;transfer
      456;1754937004;BTC;USDT;2.0;122;555;transfer
      789;1754937004;BTC;USDT;3.0;122;555;transfer
      """

      assert {:ok, _balance} = Ledger.Balance.process_content(content, "122", "0")
    end

    test "rechaza contenido con IDs duplicados" do
      content = """
      123;1754937004;BTC;USDT;1.5;122;555;transfer
      123;1754937004;BTC;USDT;2.0;122;555;transfer
      """

      assert{:error, 2} =
               Ledger.Balance.process_content(content, "122", "0")
    end

    test "rechaza IDs duplicados no consecutivos" do
      content = """
      123;1754937004;BTC;USDT;1.5;122;555;transfer
      456;1754937004;BTC;USDT;2.0;122;555;transfer
      123;1754937004;BTC;USDT;3.0;122;555;transfer
      """

      assert {:error, 3} =
               Ledger.Balance.process_content(content, "122", "0")
    end
  end

  describe "format_balance" do

    test "formatea mapa de balances correctamente" do
      balance_map = %{"BTC" => 1.5, "USDT" => 50000.0, "ETH" => 2.0}

      assert {:ok, "BTC=1.5\nETH=2.0\nUSDT=5.0e4"} =
               Ledger.FormatLedger.format_balance(balance_map)
    end

    test "mapa vacío devuelve string vacío" do
      assert {:ok, ""} = Ledger.FormatLedger.format_balance(%{})
    end

    test "un solo elemento en el mapa" do
      assert {:ok, "BTC=1.5"} = Ledger.FormatLedger.format_balance(%{"BTC" => 1.5})
    end

    test "valores negativos se formatean correctamente" do
      balance_map = %{"BTC" => -1.5, "USDT" => -50000.0}

      assert {:ok, "BTC=-1.5\nUSDT=-5.0e4"} =
               Ledger.FormatLedger.format_balance(balance_map)
    end

    test "valores decimales con muchos decimales" do
      balance_map = %{"BTC" => 0.000001, "USDT" => 123.456789}

      assert {:ok, "BTC=1.0e-6\nUSDT=123.456789"}=
               Ledger.FormatLedger.format_balance(balance_map)
    end
  end

end
