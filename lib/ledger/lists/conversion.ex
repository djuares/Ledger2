defmodule Ledger.Conversion do
  alias Ledger.{Repo, Money}

  # Convierte un monto de money1 a money2 usando la base de datos
  def convert(money1, money2, amount) do
    money1_up = String.upcase(money1)
    money2_up = String.upcase(money2)

    with {:ok, rate1} <- get_usd_rate(money1_up),
         {:ok, rate2} <- get_usd_rate(money2_up) do
      intermediate = amount * rate1
      result = intermediate / rate2
      final_result = Float.round(result, 6)
      {:ok, final_result}
    else
      {:error, msg} -> {:error, msg}
    end
  end

  # Obtiene la cotización en USD desde la base de datos
  defp get_usd_rate(currency_name) do
    case Repo.get_by(Money, name: currency_name) do
      nil -> {:error, "Moneda #{currency_name} no encontrada"}
      %Money{price: rate} -> {:ok, rate}
    end
  end

  # Convierte todos los balances a un tipo de moneda específico
  def convert_all_balances(balance_map, money_type) do
    money_type_up = String.upcase(money_type)

    total =
      Enum.reduce(balance_map, 0.0, fn {currency, amount}, acc ->
        currency_up = String.upcase(currency)
        if currency_up == money_type_up do
          acc + amount
        else
          case convert(currency_up, money_type_up, amount) do
            {:ok, converted_amount} -> acc + converted_amount
            {:error, _} -> acc
          end
        end
      end)

    {:ok, %{money_type_up => total}}
  end
end
