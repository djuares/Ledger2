defmodule Ledger.ConversionTest do
  use Ledger.RepoCase
  alias Ledger.{Conversion, Money, Repo}

  import Ecto.Query


  describe "convert/3" do
    test "convierte correctamente USD a EUR" do
      {:ok, result} = Conversion.convert("USD", "EUR", 12)
      assert Float.round(result, 6) == 10.169492
    end

    test "convierte correctamente EUR a USD" do
      {:ok, result} = Conversion.convert("EUR", "USD", 12)
      assert Float.round(result, 6) == 14.16
    end

    test "error si moneda origen no existe" do
      assert {:error, msg} = Conversion.convert("XXX", "USD", 10)
      assert msg == "Moneda XXX no encontrada"
    end

    test "error si moneda destino no existe" do
      assert {:error, msg} = Conversion.convert("USD", "YYY", 10)
      assert msg == "Moneda YYY no encontrada"
    end
  end

  describe "convert_all_balances/2" do
    test "convierte balances a moneda destino" do
      balances = %{"USD" => 12.0, "EUR" => 12.0}
      {:ok, result} = Conversion.convert_all_balances(balances, "USD")

      total = 26.16  # 12 USD + (12 EUR * 1.18)
      assert result["USD"] == Float.round(total, 6)
    end

    test "balance vacio retorna 0" do
      {:ok, result} = Conversion.convert_all_balances(%{}, "USD")
      assert result["USD"] == 0.0
    end

    test "ignora moneda inexistente en balance" do
      balances = %{"XXX" => 100.0, "USD" => 10.0}
      {:ok, result} = Conversion.convert_all_balances(balances, "USD")
      assert result["USD"] == 10.0
    end

    test "no convierte si ya es la moneda destino" do
      balances = %{"USD" => 15.0}
      {:ok, result} = Conversion.convert_all_balances(balances, "USD")
      assert result["USD"] == 15.0
    end
  end
end
