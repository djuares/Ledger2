defmodule Ledger.TransactionOperationsTest do
  use Ledger.RepoCase, async: false
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
    test "creates account with zero amount", %{users: {u1, _}, money: {m1, _}} do
      {:ok, msg} = TransactionOperations.create_high_account(u1.id, m1.id, 0)
      assert msg[:alta_cuenta] =~ "Transacción realizada correctamente"
    end
    test "transfer/4 fails if currency does not exist", %{users: {u1, _u2}} do
      result = TransactionOperations.create_high_account(u1.id, 1, 100)
      assert result == {:error, [alta_cuenta: "No existe una moneda para ese id"]}
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

      {:error, msg} = TransactionOperations.transfer(to_string(u1.id), to_string(u2.id),to_string( m1.id), Float.to_string(-50.0))
      assert msg[:realizar_transferencia] =~ "mayor que cero"

      {:error, msg} = TransactionOperations.transfer(to_string(u1.id), to_string(u2.id),to_string( m1.id), Float.to_string(0.0))
      assert msg[:realizar_transferencia] =~ "mayor que cero"

      assert_raise ArgumentError, fn ->
        TransactionOperations.transfer(to_string(u1.id), to_string(u2.id),to_string( m1.id), "ABC")
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
    test "transfer with exact available balance", %{users: {u1, u2}, money: {m1, _}} do
      {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 200)
      {:ok, _} = TransactionOperations.create_high_account(u2.id, m1.id, 0)

      {:ok, msg} = TransactionOperations.transfer(to_string(u1.id), to_string(u2.id),to_string( m1.id), Float.to_string(200.0))
      assert msg[:realizar_transferencia] =~ "Transferencia realizada"
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
    test "successful swap creates transaction", %{users: {u1, _}, money: {m1, m2}} do
      {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 500)
      {:ok, msg} = TransactionOperations.swap(to_string(u1.id), to_string(m1.id), to_string(m2.id),Float.to_string(100.0))
      assert msg[:realizar_swap] =~ "Swap realizado con ID"
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
  describe "can_undo?/1" do
    setup %{users: {u1, u2}, money: {m1, _}} do
      {:ok, alta1} = TransactionOperations.create_high_account(u1.id, m1.id, 300)
      {:ok, alta2} = TransactionOperations.create_high_account(u2.id, m1.id, 300)

      tx1 = Repo.get_by(Transaction, type: "alta_cuenta", origin_account_id: u1.id)
      tx2 = Repo.get_by(Transaction, type: "alta_cuenta", origin_account_id: u2.id)

      {:ok, txs: {tx1, tx2}}
    end

  test "last transaction for origin and destination can be undone", %{txs: {tx1, tx2}} do
    assert Ledger.TransactionOperations.can_undo?(tx1) == true
    assert Ledger.TransactionOperations.can_undo?(tx2) == true
  end

  test "transaction without destination can be undone if last", %{txs: {tx1, _}} do
    # tx1 no tiene destination_account_id
    assert Ledger.TransactionOperations.can_undo?(tx1)
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
    test "shows swap transaction details", %{users: {u1, _}, money: {m1, m2}} do
      {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 100)
      {:ok, _} = TransactionOperations.swap(to_string(u1.id), to_string(m1.id), to_string(m2.id),Float.to_string(50.0))
      tx = Repo.get_by(Transaction, type: "swap")

      {:ok, msg} = TransactionOperations.show_transaction(tx.id)
      assert msg[:view_transaction] =~ "swap"
      assert msg[:view_transaction] =~ "amount"
    end
  end
    # ----------------------------
  # AUXILIARES
  # ----------------------------

  describe "funciones auxiliares" do
    test "cuentas_dadas_de_alta?/2 detecta cuentas dadas de alta", %{users: {u1, u2}, money: {m1, _}} do
      {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 100)
      {:ok, _} = TransactionOperations.create_high_account(u2.id, m1.id, 100)
      assert TransactionOperations.cuentas_dadas_de_alta?(u1.id, u2.id)
    end

    test "parse_balance_string convierte correctamente", %{money: {m1, m2}} do
      str = "#{m1.name}=500.0\n#{m2.name}=0.5"
      map = TransactionOperations.parse_balance_string(str)
      assert map == %{m1.name => 500.0, m2.name => 0.5}
    end

    test "saldo_suficiente?/3 retorna true o false según balance", %{money: {m1, _}} do
      balance = %{m1.name => 300.0}
      assert TransactionOperations.saldo_suficiente?(balance, m1.id, 200.0)
      refute TransactionOperations.saldo_suficiente?(balance, m1.id, 400.0)
    end

    test "can_undo?/1 detecta última transacción", %{users: {u1, u2}, money: {m1, _}} do
      {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 100)
      tx = Repo.get_by(Transaction, type: "alta_cuenta", origin_account_id: u1.id)
      assert TransactionOperations.can_undo?(tx)
    end

    test "has_later_transactions?/1 detecta transacciones posteriores", %{users: {u1, u2}, money: {m1, _}} do
      {:ok, _} = TransactionOperations.create_high_account(u1.id, m1.id, 100)
      tx1 = Repo.get_by(Transaction, type: "alta_cuenta", origin_account_id: u1.id)

      :timer.sleep(1000) # esperar 1 segundo para que el timestamp sea mayor

      {:ok, _} = TransactionOperations.transfer(to_string(u1.id), to_string(u1.id), to_string(m1.id), Float.to_string(100.0))
      assert TransactionOperations.has_later_transactions?(tx1)

    end
  end

end
