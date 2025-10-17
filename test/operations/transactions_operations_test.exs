defmodule Ledger.TransactionOperationsTest do
  use Ledger.RepoCase
  import Ecto.Query
  alias Ledger.{TransactionOperations, Repo, Transaction, Money, Users, CLI}

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

  # ----------------------------
  # CREATE_HIGH_ACCOUNT
  # ----------------------------
  describe "create_high_account/3" do
    test "creates a high account transaction", %{users: {user1, _}, money: {money1, _}} do
      {:ok, msg} = TransactionOperations.create_high_account(user1.id, money1.id, 500.0)
      assert msg[:alta_cuenta] =~ "Transacción realizada correctamente con ID"

      tx = Repo.get_by(Transaction, type: "alta_cuenta", origin_account_id: user1.id, origin_currency_id: money1.id)
      assert tx.amount == 500.0
      assert tx.inserted_at != nil
    end

    test "duplicate alta_cuenta for same currency", %{users: {user1, _}, money: {money1, _}} do
      {:ok, _} = TransactionOperations.create_high_account(user1.id, money1.id, 500.0)
      {:error, msg} = TransactionOperations.create_high_account(user1.id, money1.id, 500.0)
      assert msg[:alta_cuenta] =~ "Ya existe una transacción 'alta_cuenta' para esta cuenta y moneda"
    end

    test "cannot create account with negative", %{users: {user1, _}, money: {money1, _}} do
      {:error, msg} = TransactionOperations.create_high_account(user1.id, money1.id, -100)
      assert msg[:alta_cuenta] =~"El monto debe ser mayor o igual a 0"
    end

    test "amount as invalid string", %{users: {user1, _}, money: {money1, _}} do
      {:error, msg} = TransactionOperations.create_high_account(user1.id, money1.id, "abc")
      assert msg[:alta_cuenta] =~ "is invalid"
    end

    test "fails if user or currency does not exist" do
      {:error, msg} = TransactionOperations.create_high_account(999, 1, 100)
      assert msg[:alta_cuenta] =~"No existe un usuario para ese id; No existe una moneda para ese id"
    end
  end

  # ----------------------------
  # TRANSFER
  # ----------------------------
  describe "transfer/4" do
    test "fails if accounts have no alta_cuenta", %{users: {u1, u2}, money: {m1, _}} do
      {:error, msg} = TransactionOperations.transfer(u1.id, u2.id, m1.id, 50)
      assert msg[:realizar_transferencia] =~ "Ambas cuentas deben tener una transacción de tipo 'alta_cuenta'"
    end

    test "negative, zero or invalid amount", %{users: {u1, u2}, money: {m1, _}} do
      {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 100)
      {:ok, _} = TransactionOperations.create_high_account(u2.id, m1.id, 100)

      {:error, msg} = TransactionOperations.transfer(u1.id, u2.id, m1.id, -50)
      assert msg[:realizar_transferencia] =~ "mayor que cero"

      {:error, msg} = TransactionOperations.transfer(u1.id, u2.id, m1.id, 0)
      assert msg[:realizar_transferencia] =~ "mayor que cero"

      assert_raise ArgumentError, fn ->
        TransactionOperations.transfer(u1.id, u2.id, m1.id, "abc")
      end
    end

    test "transfer with insufficient balance", %{users: {u1, u2}, money: {m1, _}} do
      {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 50)
      {:ok, _} = TransactionOperations.create_high_account(u2.id, m1.id, 50)

      {:error, msg} = TransactionOperations.transfer(u1.id, u2.id, m1.id, 100)
      assert msg[:realizar_transferencia] =~ "Saldo insuficiente"
    end
    test "successful transfer updates transaction", %{users: {u1, u2}, money: {m1, _}} do
      {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 500)
      {:ok, _} = TransactionOperations.create_high_account(u2.id, m1.id, 100)

      {:ok, msg} = TransactionOperations.transfer(to_string(u1.id), to_string(u2.id),to_string( m1.id), Float.to_string(200.0))
      assert msg[:realizar_transferencia] =~ "Transferencia realizada con ID"

      # Buscamos la transacción creada
      tx = Repo.get_by(Transaction,
        type: "transfer",
        origin_account_id: u1.id,
        destination_account_id: u2.id,
        origin_currency_id: m1.id,
        amount: 200
      )
      assert tx != nil
      assert tx.origin_account_id == u1.id
      assert tx.destination_account_id == u2.id
      assert tx.amount == 200
    end
  end

  # ----------------------------
  # SWAP
  # ----------------------------
  describe "swap/4" do
    test "negative, zero or invalid amount", %{users: {u1, _}, money: {m1, m2}} do
      {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 100)

      {:error, msg} = TransactionOperations.swap(u1.id, m1.id, m2.id, -10)
      assert msg[:realizar_swap] =~ "mayor que cero"

      {:error, msg} = TransactionOperations.swap(u1.id, m1.id, m2.id, 0)
      assert msg[:realizar_swap] =~ "mayor que cero"

      assert_raise ArgumentError, fn ->
        TransactionOperations.swap(u1.id, m1.id, m2.id, "abc")
      end
    end

    test "fails if account has no alta_cuenta", %{users: {u1, _}, money: {m1, m2}} do
      {:error, msg} = TransactionOperations.swap(u1.id, m1.id, m2.id, 50)
      assert msg[:realizar_swap] =~ "La cuenta debe tener una transacción de tipo 'alta_cuenta'"
    end

    test "fails if insufficient balance", %{users: {u1, _}, money: {m1, m2}} do
      {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 100.0)
      {:error, msg} = TransactionOperations.swap(u1.id, m1.id, m2.id, 150.0)
      assert msg[:realizar_swap] =~ "Saldo insuficiente"
    end
  end

  # ----------------------------
  # UNDO TRANSACTION
  # ----------------------------
  describe "undo_transaction/1" do
    test "fails if transaction not found" do
      {:error, msg} = TransactionOperations.undo_transaction(9999)
      assert msg[:undo] =~ "Transacción no encontrada"
    end
  test "undo alta_cuenta transaction", %{users: {u1, _}, money: {m1, _}} do
    {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 100)
    tx = Repo.get_by(Transaction, type: "alta_cuenta", origin_account_id: u1.id)

    {:ok, msg} = TransactionOperations.undo_transaction(to_string(tx.id))
    assert msg[:undo] =~ "Alta de cuenta deshecha correctamente"

    # Verificamos que la transacción ya no existe
    assert Repo.get(Transaction, tx.id) == nil
  end
  end
  # ----------------------------
  # SHOW TRANSACTION
  # ----------------------------
  describe "show_transaction/1" do
    test "returns error if not found" do
      {:error, msg} = TransactionOperations.show_transaction(9999)
      assert msg[:view_transaction] =~ "Transacción con ID 9999 no encontrada"
    end

    test "returns transaction details", %{users: {u1, _}, money: {m1, _}} do
      {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 123)
      tx = Repo.get_by(Transaction, type: "alta_cuenta", origin_account_id: u1.id)
      {:ok, msg} = TransactionOperations.show_transaction(tx.id)
      assert msg[:view_transaction] =~ "#{tx.id}"
      assert msg[:view_transaction] =~ "123"
    end

    test "transaction with nil destination_account", %{users: {u1, _}, money: {m1, _}} do
      {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 100)
      tx = Repo.get_by(Transaction, type: "alta_cuenta", origin_account_id: u1.id)

      {:ok, msg} = TransactionOperations.show_transaction(tx.id)
      assert msg[:view_transaction] =~ "origin_account_id"
      assert msg[:view_transaction] =~ Integer.to_string(u1.id)
    end
  end
end
