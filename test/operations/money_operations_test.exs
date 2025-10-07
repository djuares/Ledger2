defmodule Ledger.MoneyOperationsTest do
  use Ledger.RepoCase
  alias Ledger.{MoneyOperations, Repo, Money}

  describe "create_money/2" do
    test "inserts a money record correctly" do
      # Call the function to create a Money record
      {:ok, msg} = MoneyOperations.create_money("USD", 100.0)

      # Check that the returned message contains the ID
      assert msg =~ "Money created successfully with ID"

      # Fetch the record from the database to ensure it was inserted
      money = Repo.get_by(Money, name: "USD")

      # Check that the price is correctly stored
      assert money.price == 100.0

      # Ensure timestamps are set automatically
      assert money.inserted_at != nil
      assert money.updated_at != nil
    end

    test "fails when name is missing" do
      # Try creating Money with an empty name
      {:error, changeset} = MoneyOperations.create_money("", 100.0)

      # Traverse changeset errors to get a map of field errors
      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)

      # Check that there is an error on the name field
      assert %{name: [_]} = errors
    end

    test "fails when price is negative" do
      # Try creating Money with a negative price
      {:error, changeset} = MoneyOperations.create_money("USD", -10.0)

      # Extract the errors from the changeset
      errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)

      # Check that there is an error on the price field
      assert %{price: [_]} = errors
    end
  end
end
