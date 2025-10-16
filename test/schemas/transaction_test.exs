defmodule Ledger.TransactionTest do
  use Ledger.RepoCase

  alias Ledger.{Transaction, Users, Money, Repo}
  
  # Helper para mapear errores de changeset a un map legible
  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

  setup do
    # Crear usuarios de prueba
    {:ok, origin_user} =
      %Users{}
      |> Users.create_changeset(%{username: "sofia", birth_date: ~D[2000-01-01]})
      |> Repo.insert()

    {:ok, dest_user} =
      %Users{}
      |> Users.create_changeset(%{username: "mateo", birth_date: ~D[2001-01-01]})
      |> Repo.insert()

    # Crear moneda de prueba
    {:ok, currency} =
      %Money{}
      |> Money.changeset(%{name: "USD", price: 1.0})
      |> Repo.insert()

    %{origin_user: origin_user, dest_user: dest_user, currency: currency}
  end

  describe "valid transaction creation" do
    test "create transaction and verify id, timestamps and fields", %{
      origin_user: origin_user,
      dest_user: dest_user,
      currency: currency
    } do
      attrs = %{
        timestamp: DateTime.utc_now(),
        amount: 100.0,
        type: "transfer",
        origin_currency_id: currency.id,
        destination_currency_id: currency.id,
        origin_account_id: origin_user.id,
        destination_account_id: dest_user.id
      }

      {:ok, tx} =
        %Transaction{}
        |> Transaction.changeset(attrs)
        |> Repo.insert()

      # ID verification
      assert is_integer(tx.id) and tx.id > 0

      # Timestamps
      assert %NaiveDateTime{} = tx.inserted_at
      assert %NaiveDateTime{} = tx.updated_at

      # Field verification
      assert tx.amount == 100.0
      assert tx.type == "transfer"
      assert tx.origin_account_id == origin_user.id
      assert tx.destination_account_id == dest_user.id
      assert tx.origin_currency_id == currency.id
      assert tx.destination_currency_id == currency.id
    end
  end

  describe "required fields validation" do
    test "fails if required fields are missing" do
      changeset = Transaction.changeset(%Transaction{}, %{})
      refute changeset.valid?

      errors = errors_on(changeset)

      assert "can't be blank" in errors.timestamp
      assert "can't be blank" in errors.amount
      assert "can't be blank" in errors.type
      assert "can't be blank" in errors.origin_currency_id
      assert "can't be blank" in errors.origin_account_id
    end
  end

  describe "account existence validation" do
    test "fails if origin account does not exist", %{dest_user: dest_user, currency: currency} do
      attrs = %{
        timestamp: DateTime.utc_now(),
        amount: 50.0,
        type: "transfer",
        origin_currency_id: currency.id,
        destination_currency_id: currency.id,
        origin_account_id: 999_999, # inexistente
        destination_account_id: dest_user.id
      }

      changeset = Transaction.changeset(%Transaction{}, attrs)
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "origin account must exist" in errors.origin_account_id
    end

    test "fails if destination account does not exist", %{origin_user: origin_user, currency: currency} do
      attrs = %{
        timestamp: DateTime.utc_now(),
        amount: 50.0,
        type: "transfer",
        origin_currency_id: currency.id,
        destination_currency_id: currency.id,
        origin_account_id: origin_user.id,
        destination_account_id: 999_999 # inexistente
      }

      changeset = Transaction.changeset(%Transaction{}, attrs)
      refute changeset.valid?

      errors = errors_on(changeset)
      assert "destination account must exist" in errors.destination_account_id
    end
  end
end
