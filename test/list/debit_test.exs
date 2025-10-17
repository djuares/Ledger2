defmodule Ledger.DebitTest do
  use Ledger.RepoCase
  alias Ledger.Debit

  describe "debit_balance/1" do
    test "returns empty map when input list is empty" do
      assert Debit.debit_balance([]) == %{}
    end

    test "processes a single debit correctly" do
      debits = ["1;1234567890;BTC;_;100;_;account1;transfer"]
      result = Debit.debit_balance(debits)
      assert result == %{"BTC" => -100.0}
    end

    test "accumulates multiple debits of the same currency" do
      debits = [
        "1;1234567890;BTC;_;50;_;account1;transfer",
        "2;1234567890;BTC;_;25;_;account2;transfer"
      ]
      result = Debit.debit_balance(debits)
      assert result == %{"BTC" => -75.0}
    end

    test "handles multiple currencies independently" do
      debits = [
        "1;1234567890;BTC;_;50;_;account1;transfer",
        "2;1234567890;ETH;_;30;_;account2;transfer"
      ]
      result = Debit.debit_balance(debits)
      assert result == %{"BTC" => -50.0, "ETH" => -30.0}
    end
  end
end
