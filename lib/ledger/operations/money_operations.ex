defmodule Ledger.MoneyOperations do
  alias Ledger.{Repo, Money}

  @doc """
  Creates a new Money record with the given name and USD price.
  """
  def create_money(money_name, usd_price) do
    attrs = %{
      name: money_name,
      price: usd_price,
    }

    %Money{}
    |> Money.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        {:ok, "Money created successfully with ID #{user.id}"}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
