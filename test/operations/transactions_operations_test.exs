defmodule Ledger.TransactionOperationsTest do
  use Ledger.RepoCase
  alias Ledger.{TransactionOperations, Repo, Transaction, Money, Users}

  setup do
    Repo.delete_all(Transaction)
    Repo.delete_all(Money)
    Repo.delete_all(Users)

    user1 = %Users{username: "Sofía", birth_date: ~D[2000-01-01]} |> Repo.insert!()
    user2 = %Users{username: "Mateo", birth_date: ~D[2000-02-01]} |> Repo.insert!()

    money1 = %Money{name: "USD", price: 1.0} |> Repo.insert!()
    money2 = %Money{name: "BTC", price: 50000.0} |> Repo.insert!()

    {:ok, users: {user1, user2}, money: {money1, money2}}
  end

  describe "create_high_account/3" do
    test "creates a high account transaction", %{users: {user1, _}, money: {money1, _}} do
      {:ok, msg} = TransactionOperations.create_high_account(user1.id, money1.id, 500.0)
      assert msg[:alta_cuenta] =~ "Transacción realizada correctamente con ID"

      tx = Repo.get_by(Transaction, type: "alta_cuenta", origin_account_id: user1.id, origin_currency_id: money1.id)
      assert tx.amount == 500.0
      assert tx.inserted_at != nil
    end
  end

  describe "transfer/4" do
    test "fails if accounts have no alta_cuenta", %{users: {user1, user2}, money: {money1, _}} do
      {:error, msg} = TransactionOperations.transfer(user1.id, user2.id, money1.id, 50)
      assert msg[:realizar_transferencia] =~ "Ambas cuentas deben tener una transacción de tipo 'alta_cuenta'"
    end


  test "no se puede dar de alta una cuenta dos veces con la misma moneda" , %{users: {user1, _user2}, money: {money1, _money2}} do
    {:ok, msg} = TransactionOperations.create_high_account(user1.id, money1.id, 500.0)
    assert msg[:alta_cuenta] =~ "Transacción realizada correctamente con ID"
    {:error, msg} = TransactionOperations.create_high_account(user1.id, money1.id, 500.0)
    assert msg[:alta_cuenta] =~ "Ya existe una transacción 'alta_cuenta' para esta cuenta y moneda"
  end

  end

  describe "swap/4" do
    test "fails if account has no alta_cuenta", %{users: {user1, _}, money: {money1, money2}} do
      {:error, msg} = TransactionOperations.swap(user1.id, money1.id, money2.id, 50)
      assert msg[:realizar_swap] =~ "La cuenta debe tener una transacción de tipo 'alta_cuenta'"
    end

    test "fails if insufficient balance", %{users: {user1, _}, money: {money1, money2}} do
      {:ok, _} = TransactionOperations.create_high_account(user1.id, money1.id, 100.0)
      {:error, msg} = TransactionOperations.swap(user1.id, money1.id, money2.id, 150.0)
      assert msg[:realizar_swap] =~ "Saldo insuficiente para realizar el swap con la moneda de origen"
    end

  end
  describe "undo_transaction/1" do
    test "fails if transaction not found" do
      {:error, msg} = TransactionOperations.undo_transaction(9999)
      assert msg[:undo] =~ "Transacción con ID 9999 no encontrada"
    end


  end

  describe "show_transaction/1" do
    test "returns error if not found" do
      {:error, msg} = TransactionOperations.show_transaction(9999)
      assert msg[:view_transaction] =~ "Transacción con ID 9999 no encontrada"
    end

    test "returns transaction details", %{users: {user1, _}, money: {money1, _}} do
      {:ok, _} = TransactionOperations.create_high_account(user1.id, money1.id, 123)
      tx = Repo.get_by(Transaction, type: "alta_cuenta", origin_account_id: user1.id)
      {:ok, msg} = TransactionOperations.show_transaction(tx.id)
      assert msg[:view_transaction] =~ "#{tx.id}"
      assert msg[:view_transaction] =~ "123"
    end


  end
end
