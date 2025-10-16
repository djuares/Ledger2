defmodule Ledger.MoneyOperationsTest do
  use Ledger.RepoCase
  alias Ledger.{MoneyOperations, Repo, Money}

  describe "create_money/2" do
    test "inserts a money record correctly" do
      {:ok, msg} = MoneyOperations.create_money("USD", 100.0)
      assert msg =~ "Money created successfully with ID"

      money = Repo.get_by(Money, name: "USD")
      assert money.price == 100.0
      assert money.inserted_at != nil
      assert money.updated_at != nil
    end

    test "fails when name is missing" do
      {:error, changeset} = MoneyOperations.create_money("", 100.0)
      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert %{name: [_]} = errors
    end

    test "fails when price is negative" do
      {:error, changeset} = MoneyOperations.create_money("USD", -10.0)
      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
      assert %{price: [_]} = errors
    end
  end

  describe "edit_money/2" do
    test "updates the price successfully" do
      {:ok, _} = MoneyOperations.create_money("EUR", 1.1)
      money = Repo.get_by(Money, name: "EUR")

      {:ok, msg} = MoneyOperations.edit_money(money.id, 1.2)
      assert msg =~ "updated successfully"

      updated = Repo.get(Money, money.id)
      assert updated.price == 1.2
    end

    test "returns error when money not found" do
      {:error, msg} = MoneyOperations.edit_money(999, 1.5)
      assert msg == "Money with ID 999 not found"
    end
  end

  describe "delete_money/1" do
    test "deletes a money record successfully" do
      {:ok, _} = MoneyOperations.create_money("GBP", 1.3)
      money = Repo.get_by(Money, name: "GBP")

      {:ok, msg} = MoneyOperations.delete_money(money.id)
      assert msg =~ "deleted successfully"

      assert Repo.get(Money, money.id) == nil
    end

    test "returns error when money not found" do
      {:error, msg} = MoneyOperations.delete_money(999)
      assert msg == "Money with ID 999 not found"
    end

    test "delete_money/1 returns error when money has associated transactions" do
      # Crear las monedas
      origin_currency =
        Repo.insert!(%Ledger.Money{name: "USD", price: 1.0})

      destination_currency =
        Repo.insert!(%Ledger.Money{name: "ARS", price: 900.0})

      # Crear una transacción asociada
      Repo.insert!(%Ledger.Transaction{
        origin_currency_id: origin_currency.id,
        destination_currency_id: destination_currency.id,
        amount: 100.0,
        type: "transfer",
        timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
      })

      # Intentar eliminar la moneda con transacción asociada
      result = Ledger.MoneyOperations.delete_money(origin_currency.id)

      assert {:error, _reason} = result
    end


end


  describe "show_money/1" do
    test "returns the money record correctly" do
      {:ok, _} = MoneyOperations.create_money("JPY", 150.0)
      money = Repo.get_by(Money, name: "JPY")

      {:ok, msg} = MoneyOperations.show_money(money.id)
      assert msg =~ "JPY"
      assert msg =~ "150.0"
    end

    test "returns error when money not found" do
      {:error, msg} = MoneyOperations.show_money(999)
      assert msg == "Money with ID 999 not found"
    end
  end
end
