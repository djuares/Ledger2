defmodule AcreditTest do
  use ExUnit.Case

  test "acredit_balance calcula correctamente acreditaciones" do
    accreditations = [
    "1;1754937004;BTC;USDT;1;55,5;122;transfer",
    "1;1754937004;USDT;BTC;55000;555;122;transfer"
  ]

    result = Ledger.Acredit.acredit_balance(accreditations)
    # Dependiendo de las tasas de conversión
    assert %{"BTC" => 1.0, "USDT" => 55000.0} = result
  end

end
