defmodule ConversionTest do
  use ExUnit.Case


    test "conversión exitosa entre monedas válidas" do
      assert {:ok,1.218182} = Ledger.Conversion.convert("USDT", "BTC", 67000)
      assert {:ok, 67000.01} = Ledger.Conversion.convert("BTC", "USDT", 1.218182)
    end

    test "error cuando moneda origen no existe" do
      assert {:error, "Una o ambas monedas no son válidas"} =
               Ledger.Conversion.convert("INVALID", "BTC", 100.0)
    end

    test "error cuando moneda destino no existe" do
      assert {:error, "Una o ambas monedas no son válidas"} =
               Ledger.Conversion.convert("BTC", "INVALID", 100.0)
    end

    test "error cuando ambas monedas no existen" do
      assert {:error, "Una o ambas monedas no son válidas"} =
               Ledger.Conversion.convert("INVALID1", "INVALID2", 100.0)
    end

    test "redondeo correcto a 6 decimales" do
      assert {:ok, 0.000001} = Ledger.Conversion.convert("USDT", "BTC", 0.055555)
    end

    test "conversión con amount cero" do
      assert {:ok, 0.0} = Ledger.Conversion.convert("BTC", "USDT", 0.0)
    end


    test "conversión de múltiples balances a una moneda" do
      balance_map = %{"BTC" => 1.0, "USDT" => 50000.0, "ETH" => 2.0}

      assert {:ok, %{"BTC" => 2.018182}} = Ledger.Conversion.convert_all_balances(balance_map, "BTC")
    end

    test "moneda que ya está en el tipo objetivo no se convierte" do
      balance_map = %{"BTC" => 2.5, "USDT" => 1000.0}

      assert {:ok, %{"BTC" =>  2.518182}} = Ledger.Conversion.convert_all_balances(balance_map, "BTC")
    end

    test "maneja errores de conversión individuales" do
      balance_map = %{"BTC" => 1.0, "INVALID" => 100.0}

      # El balance de la moneda inválida debería ignorarse
      assert {:ok, %{"BTC" => 1.0}} = Ledger.Conversion.convert_all_balances(balance_map, "BTC")
    end

    test "mapa vacío devuelve cero" do
      assert {:ok, %{"BTC" => 0.0}} = Ledger.Conversion.convert_all_balances(%{}, "BTC")
    end

    test "conversión de múltiples monedas con diferentes tasas" do
      balance_map = %{
        "BTC" => 1.0,
        "USDT" => 50000.0,  # ≈ 0.9 BTC (50000 * 0.000018)
        "ETH" => 2.0        # ≈ 0.12 BTC (2.0 * 0.06)
      }

      # Total aproximado: 1.0 + 0.9 + 0.12 = 2.02 BTC
      assert {:ok, result} = Ledger.Conversion.convert_all_balances(balance_map, "BTC")
      assert_in_delta result["BTC"], 2.02, 0.01
    end

end
