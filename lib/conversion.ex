defmodule Ledger.Conversion do

def convert(money1, money2, amount) do
    currencies = load_currencies()
    money1_up = String.upcase(money1)
    money2_up = String.upcase(money2)

    if Map.has_key?(currencies, money1_up) and Map.has_key?(currencies, money2_up) do
      rate1 = currencies[money1_up]
      rate2 = currencies[money2_up]

      intermediate = amount * rate1
      result = (intermediate / rate2)
      final_result = Float.round(result, 6)

      {:ok, final_result}
    else
      {:error, "Una o ambas monedas no son válidas"}
    end
  end

def load_currencies() do
  case File.read("data/input/money.csv") do
    {:ok, content} ->
      currencies_map = content
        |> String.split("\n", trim: true)
        |> Enum.map(&String.split(&1, ";"))
        |> Enum.reduce(%{}, fn [currency, rate], acc ->
          {rate_float, _} = Float.parse(rate)
          Map.put(acc, String.upcase(currency), rate_float)
        end)
      currencies_map
  end
end
def convert_all_balances(balance_map, money_type) do
  total = Enum.reduce(balance_map, 0.0, fn {currency, amount}, acc ->
    if currency == money_type do
      acc + amount
    else
      case convert(currency, money_type, amount) do
        {:ok, converted_amount} -> acc + converted_amount
        {:error, _} -> acc
      end
    end
  end)

  {:ok, %{money_type => total}}  # ← Devuelve {:ok, map}
end

end
