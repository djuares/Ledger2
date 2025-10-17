defmodule Ledger.MoneyOperationsTest do
  use Ledger.RepoCase
  alias Ledger.{MoneyOperations, Repo, Money}

  describe "create_money/2" do
    test "inserts a money record correctly" do
      {:ok, msg} = MoneyOperations.create_money("USD", 100.0)
      assert msg[:crear_moneda] =~ "Moneda creada correctamente con ID"

      money = Repo.get_by(Money, name: "USD")
      assert money.price == 100.0
      assert money.inserted_at != nil
      assert money.updated_at != nil
    end

    test "fails when name is too short" do
      {:error, msg} = MoneyOperations.create_money("AB", 100.0)
      assert msg[:crear_moneda] =~ "El nombre debe tener entre 3 y 4 caracteres"
    end

    test "fails when name is too long" do
      {:error, msg} = MoneyOperations.create_money("ABCDE", 100.0)
      assert msg[:crear_moneda] =~ "El nombre debe tener entre 3 y 4 caracteres"
    end
  end

  describe "edit_money/2" do
    test "updates the price successfully" do
      {:ok, _} = MoneyOperations.create_money("EUR", 1.1)
      money = Repo.get_by(Money, name: "EUR")

      {:ok, msg} = MoneyOperations.edit_money(money.id, 1.2)
      assert msg[:editar_moneda] =~ "updated successfully"

      updated = Repo.get(Money, money.id)
      assert updated.price == 1.2
    end

    test "returns error when money not found" do
      {:error, msg} = MoneyOperations.edit_money(999, 1.5)
      assert msg[:editar_moneda] =~ "Money with ID 999 not found"
    end
  end

  describe "delete_money/1" do
    test "deletes a money record successfully" do
      {:ok, _} = MoneyOperations.create_money("GBP", 1.3)
      money = Repo.get_by(Money, name: "GBP")

      {:ok, msg} = MoneyOperations.delete_money(money.id)
      assert msg =~ "Money with ID #{money.id} deleted successfully"
      assert Repo.get(Money, money.id) == nil
    end

    test "returns error when money not found" do
      {:error, msg} = MoneyOperations.delete_money(999)
      assert msg[:borrar_moneda] =~ "Money with ID 999 not found"
    end

    test "returns error when money has associated transactions" do
      origin_currency = Repo.insert!(%Money{name: "USD", price: 1.0})
      destination_currency = Repo.insert!(%Money{name: "ARS", price: 900.0})

      Repo.insert!(%Ledger.Transaction{
        origin_currency_id: origin_currency.id,
        destination_currency_id: destination_currency.id,
        amount: 100.0,
        type: "transfer",
        timestamp: DateTime.utc_now() |> DateTime.truncate(:second)
      })

      {:error, msg} = MoneyOperations.delete_money(origin_currency.id)
      assert msg[:borrar_moneda] =~ "Cannot delete Money"
    end
  end

  describe "show_money/1" do
    test "returns the money record correctly" do
      {:ok, _} = MoneyOperations.create_money("JPY", 150.0)
      money = Repo.get_by(Money, name: "JPY")

      {:ok, msg} = MoneyOperations.show_money(money.id)
      assert msg[:ver_moneda] =~ "JPY"
      assert msg[:ver_moneda] =~ "150.0"
    end

    test "returns error when money not found" do
      {:error, msg} = MoneyOperations.show_money(999)
      assert msg[:ver_moneda] =~ "Moneda no encontrada"
    end
  end

  describe "create_money/2 - additional edge cases" do
    test "fails when price is negative" do
      {:error, msg} = MoneyOperations.create_money("BTC", -100.0)
      assert msg[:crear_moneda] =~ "price"
    end


    test "fails when name is not unique" do
      {:ok, _} = MoneyOperations.create_money("ETH", 2000.0)
      {:error, msg} = MoneyOperations.create_money("ETH", 2500.0)
      assert msg[:crear_moneda] =~ "name"
    end
  end

  describe "edit_money/2 - additional tests" do
    setup do
      {:ok, _} = MoneyOperations.create_money("TEST", 1.0)
      money = Repo.get_by(Money, name: "TEST")
      %{money: money}
    end

    test "fails when updating with invalid price", %{money: money} do
      {:error, msg} = MoneyOperations.edit_money(money.id, -50.0)
      assert msg[:crear_moneda] =~ "price"
    end

    test "fails when updating with non-numeric price", %{money: money} do
      # Esto probablemente fallará en el cast del changeset
      {:error, msg} = MoneyOperations.edit_money(money.id, "invalid")
      assert msg[:crear_moneda] =~ "price"
    end

    test "updates timestamp when price changes", %{money: money} do
      original_updated_at = money.updated_at
      :timer.sleep(1000)

      {:ok, _} = MoneyOperations.edit_money(money.id, 2.0)
      updated = Repo.get(Money, money.id)

      assert updated.updated_at != original_updated_at
    end
  end

end
