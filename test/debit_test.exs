defmodule DebitTest do
  use ExUnit.Case

  test "debit_balance calcula correctamente debitaciones" do
    accreditations = [
    "1;1754937004;BTC;USDT;1;55,122;000;transfer",
    "1;1754937004;USDT;BTC;55000;122;555;transfer"
  ]

    result = Ledger.Debit.debit_balance(accreditations)
    # Dependiendo de las tasas de conversión
    assert %{"BTC" => -1.0, "USDT" => -55000.0} = result
  end

end
