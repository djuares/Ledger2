defmodule Ledger.TransactionOperationsTest do
  use Ledger.RepoCase
  alias Ledger.{TransactionOperations, Transaction, Repo, Users, Money}

  describe "create_high_account/2" do
    setup do
      # Create a user
      {:ok, user} =
        %Users{}
        |> Users.create_changeset(%{username: "sofia", birth_date: ~D[2000-01-01]})
        |> Repo.insert()

      # Create a currency
      {:ok, currency} =
        %Money{}
        |> Money.changeset(%{name: "USD", price: 1.0})
        |> Repo.insert()

      %{user: user, currency: currency}
    end

    test "returns success message and inserts a high_account transaction", %{user: user, currency: currency} do
      # Call the function under test
      {:ok, msg} = TransactionOperations.create_high_account(user.id, currency.id)

      # Assert that the message contains the ID
      assert msg =~ "Transactions made successfully with ID"

      # Extract the ID from the message
      [id_str] = Regex.run(~r/ID (\d+)/, msg, capture: :all_but_first)
      tx_id = String.to_integer(id_str)

      # Assert that the transaction actually exists in the DB
      tx_from_db = Repo.get!(Transaction, tx_id)
      assert tx_from_db.type == "high_account"
      assert tx_from_db.amount == 0.0
      assert tx_from_db.origin_account_id == user.id
      assert tx_from_db.origin_currency_id == currency.id
    end
  end
end
