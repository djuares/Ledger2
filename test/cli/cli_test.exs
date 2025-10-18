
defmodule CliTest do
  import Ledger.CLI
  use Ledger.RepoCase
  import ExUnit.CaptureIO
  alias Ledger.{TransactionOperations, Transaction, Repo, Users, Money, UserOperations, MoneyOperations}

  describe "args_to_internal_representation/1" do
    test "convierte crear_usuario correctamente" do
      result = Ledger.CLI.args_to_internal_representation({["crear_usuario"], [n: "Sofía", b: "2000-01-01"]})
      assert result == {"crear_usuario", "Sofía", "2000-01-01"}
    end

    test "convierte editar_usuario correctamente" do
      result = Ledger.CLI.args_to_internal_representation({["editar_usuario"], [id: "10", n: "Ana"]})
      assert result == {"editar_usuario", "10", "Ana"}
    end
    test "convierte borrar_usuario correctamente" do
      result = Ledger.CLI.args_to_internal_representation({["borrar_usuario"], [id: "3"]})
      assert result == {"borrar_usuario", "3"}
    end

    test "convierte ver_usuario correctamente" do
      result = Ledger.CLI.args_to_internal_representation({["ver_usuario"], [id: "8"]})
      assert result == {"ver_usuario", "8"}
    end

    test "convierte crear_moneda correctamente" do
      result = Ledger.CLI.args_to_internal_representation({["crear_moneda"], [n: "USD", p: "1.0"]})
      assert result == {"crear_moneda", "USD", "1.0"}
    end

    test "convierte alta_cuenta correctamente" do
      result = Ledger.CLI.args_to_internal_representation({["alta_cuenta"], [u: "1", m: "2", a: "500"]})
      assert result == {"alta_cuenta", "1", "2", "500"}
    end

    test "convierte realizar_transferencia correctamente" do
      result =
        Ledger.CLI.args_to_internal_representation({["realizar_transferencia"], [o: "1", d: "2", m: "3", a: "100"]})

      assert result == {"realizar_transferencia", "1", "2", "3", "100"}
    end

    test "convierte realizar_swap correctamente" do
      result =
        Ledger.CLI.args_to_internal_representation({["realizar_swap"], [u: "1", mo: "USD", md: "ARS", a: "100"]})

      assert result == {"realizar_swap", "1", "USD", "ARS", "100"}
    end

    test "convierte deshacer_transaccion correctamente" do
      result = Ledger.CLI.args_to_internal_representation({["deshacer_transaccion"], [id: "22"]})
      assert result == {"deshacer_transaccion", "22"}
    end

    test "convierte ver_transaccion correctamente" do
      result = Ledger.CLI.args_to_internal_representation({["ver_transaccion"], [id: "5"]})
      assert result == {"ver_transaccion", "5"}
    end

    test "convierte balance correctamente" do
      result = Ledger.CLI.args_to_internal_representation({["balance"], [c1: "10", m: "USD"]})
      assert result == {"balance", "10", "USD"}
    end

    test "convierte transacciones con valores por defecto" do
      result = Ledger.CLI.args_to_internal_representation({["transacciones"], []})
      assert result == {"transacciones", "0", "0"}
    end

    test "retorna :help para comando desconocido" do
      assert Ledger.CLI.args_to_internal_representation({["desconocido"], []}) == :help
    end
  end
  describe "commands to list" do
    test ":help returned by option parsing with -h and --help options" do
      assert parse_args(["-h",     "anything"]) == :help
      assert parse_args(["--help", "anything"]) == :help
    end
    test "transaction default" do
      assert parse_args(["transacciones"]) == {"transacciones", "0", "0" }
    end
      test "transaction with arguments c1 " do
      assert parse_args(["transacciones", "-c1=312"]) == {"transacciones", "312", "0"}
    end
    test "transaction with arguments c1, c2 " do
        assert parse_args(["transacciones", "-c1=312", "-c2=133"]) == {"transacciones", "312", "133"}
    end

    test "balance with arguments" do
      assert parse_args(["balance","-c1=312", "-m=money_type"]) == {"balance",  "312", "money_type"}
    end
    test "balance default" do
      assert parse_args(["balance", "-c1=312"]) ==    {"balance", "312", "0"}
    end

    end
  describe "user_commands" do
    test "create_user" do
      assert parse_args(["crear_usuario", "-n=sofia", "-b=1999-01-01"]) ==
            {"crear_usuario", "sofia", "1999-01-01"}
    end
    test "edit_user" do
      assert parse_args(["editar_usuario", "-id=312", "-n=sofia"]) ==
            {"editar_usuario", "312", "sofia"}
    end
    test "delete_user" do
      assert parse_args(["borrar_usuario", "-id=312"]) ==
            {"borrar_usuario", "312"}
    end
    test "view_user" do
      assert parse_args(["ver_usuario", "-id=312"]) ==
            {"ver_usuario", "312"}
    end
  end

   describe "money commands" do
    test "parse money_create" do
      assert parse_args(["crear_moneda", "-n=Bitcoin", "-p=68000"]) ==
             {"crear_moneda", "Bitcoin", "68000"}
    end

    test "parse edit_money" do
      assert parse_args(["editar_moneda", "-id=5", "-p=70000"]) ==
             {"editar_moneda", "5", "70000"}
    end

    test "parse delete_money" do
      assert parse_args(["borrar_moneda", "-id=5"]) ==
             {"borrar_moneda", "5"}
    end

    test "parse view_money" do
      assert parse_args(["ver_moneda", "-id=5"]) ==
             {"ver_moneda", "5"}
    end
  end

  describe "account and transaction commands" do
    test "parse high_account" do
      assert parse_args(["alta_cuenta", "-u=7", "-m=3", "-a=600"]) ==
             {"alta_cuenta", "7", "3", "600"}
    end

    test "parse make_transfer" do
      assert parse_args(["realizar_transferencia", "-o=2", "-d=5", "-m=BTC" ,"-a=312"]) ==
             {"realizar_transferencia", "2", "5", "BTC", "312"}
    end

    test "parse make_swap" do
      assert parse_args(["realizar_swap", "-u=4", "-mo=2", "-md=3", "-a=100"]) ==
             {"realizar_swap", "4", "2", "3", "100"}
    end
    test "parse make_swap cambiado de orden" do
      assert parse_args(["realizar_swap", "-md=3", "-a=100", "-u=4", "-mo=2"]) ==
             {"realizar_swap", "4", "2", "3", "100"}
    end

    test "parse undo_transaction" do
      assert parse_args(["deshacer_transaccion", "-id=12"]) ==
             {"deshacer_transaccion", "12"}
    end

    test "parse view_transaction" do
      assert parse_args(["ver_transaccion", "-id=12"]) ==
             {"ver_transaccion", "12"}
    end

end

describe "CLI.process/1" do
  setup do
    # Limpiar la base de datos antes de cada test
    Repo.delete_all(Transaction)
    Repo.delete_all(Money)
    Repo.delete_all(Users)

    # Crear usuarios y monedas
    user1 = %Users{username: "Sofía", birth_date: ~D[2000-01-01]} |> Repo.insert!()
    user2 = %Users{username: "Mateo", birth_date: ~D[2000-02-01]} |> Repo.insert!()

    money1 = %Money{name: "USDT", price: 1.0} |> Repo.insert!()
    money2 = %Money{name: "BTCS", price: 50000.0} |> Repo.insert!()

    {:ok, users: {user1, user2}, money: {money1, money2}}
  end

  # --- Usuarios ---
  test "crear_usuario crea usuario en BD" do
    Ledger.CLI.process({"crear_usuario", "sofia", "2000-01-01"})
    user = Repo.get_by(Users, username: "sofia")
    assert user != nil
    assert user.birth_date == ~D[2000-01-01]
  end

  test "crear_usuario con fecha inválida devuelve error" do
    output = capture_io(fn ->
      Ledger.CLI.process({"crear_usuario", "sofia", "2000-99-99"})
    end)
    assert output =~ "Formato de fecha inválido"
  end

  test "editar_usuario actualiza nombre en BD", %{users: {user1, _}} do
    Ledger.CLI.process({"editar_usuario", user1.id, "luciana"})
    user = Repo.get(Users, user1.id)
    assert user.username == "luciana"
  end

  test "borrar_usuario elimina usuario", %{users: {user1, _}} do
    Ledger.CLI.process({"crear_usuario", "Gloria", "1995-05-05"})
    user = Repo.get_by(Users, username: "Gloria")
    Ledger.CLI.process({"borrar_usuario", user.id})
    user = Repo.get(Users, user.id)
    assert user == nil
  end

  # --- Monedas ---
  test "crear_moneda crea moneda en BD" do
    Ledger.CLI.process({"crear_moneda", "ETH", 3000})
    money = Repo.get_by(Money, name: "ETH")
    assert money != nil
    assert money.price == 3000
  end

  test "editar_moneda actualiza precio en BD", %{money: {money1, _}} do
    Ledger.CLI.process({"editar_moneda", money1.id, 2.0})
    money = Repo.get(Money, money1.id)
    assert money.price == 2.0
  end


  test "ver_moneda muestra información correcta", %{money: {_, money2}} do
    output = capture_io(fn -> Ledger.CLI.process({"ver_moneda", money2.id}) end)
    assert output =~ money2.name
  end

  # --- Transacciones ---
  test "alta_cuenta genera transacción en BD", %{users: {user1, _}, money: {money1, _}} do
    Ledger.CLI.process({"alta_cuenta", user1.id, money1.id, 50})
    tx = Repo.one(
      from t in Transaction,
        where: t.origin_account_id == ^user1.id and t.origin_currency_id == ^money1.id,
        order_by: [desc: t.inserted_at],
        limit: 1
    )
    assert tx.amount == 50
    assert tx.type == "alta_cuenta"
  end

  test "ver_transaccion muestra información correcta", %{users: {user1, _}, money: {money1, _}} do
    Ledger.CLI.process({"alta_cuenta", user1.id, money1.id, 50})
    tx = Repo.one(from t in Transaction, where: t.origin_account_id == ^user1.id, limit: 1)
    output = capture_io(fn -> Ledger.CLI.process({"ver_transaccion", tx.id}) end)
    assert output =~ "id= #{tx.id}"
  end

  test "deshacer_transaccion funciona correctamente", %{users: {user1, _}, money: {money1, _}} do
    Ledger.CLI.process({"alta_cuenta", user1.id, money1.id, 50})
    tx = Repo.one(from t in Transaction, where: t.origin_account_id == ^user1.id, limit: 1)
    output = capture_io(fn -> Ledger.CLI.process({"deshacer_transaccion", tx.id}) end)
    assert output =~ "undo" or output =~ "No se puede deshacer"
  end
    test "crear_usuario con fecha inválida no inserta usuario" do
    Ledger.CLI.process({"crear_usuario", "mario", "2000-99-99"})
    user = Repo.get_by(Users, username: "mario")
    assert user == nil
  end

  test "realizar_transferencia falla si no hay fondos insuficientes", %{users: {user1, user2}, money: {money1, _}} do
    Ledger.CLI.process({"realizar_transferencia", user1.id, user2.id, money1.id, 9999})
    tx = Repo.one(from t in Transaction,
                  where: t.origin_account_id == ^user1.id and t.destination_account_id == ^user2.id,
                  order_by: [desc: t.inserted_at],
                  limit: 1)
    assert tx == nil
  end
  test "crear_usuario con nombre vacío no inserta", %{users: _} do
  Ledger.CLI.process({"crear_usuario", "", "2000-01-01"})
  assert Repo.get_by(Users, username: "") == nil
end

test "transferencia exitosa", %{users: {u1, u2}, money: {m1, _}} do
    Ledger.CLI.process({"alta_cuenta", u1.id, m1.id, 500})
    Ledger.CLI.process({"alta_cuenta", u2.id, m1.id, 500})
    Ledger.CLI.process({"realizar_transferencia", to_string(u1.id), to_string(u2.id), to_string(m1.id), Float.to_string(200.0)})

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

test "transferencia con monto mayor al saldo no se crea", %{users: {user1, user2}, money: {money1, _}} do
  Ledger.CLI.process({"alta_cuenta", user1.id, money1.id, 50})
  Ledger.CLI.process({"realizar_transferencia", user1.id, user2.id, money1.id, 1000})
  tx = Repo.one(from t in Transaction, where: t.origin_account_id == ^user1.id and t.destination_account_id == ^user2.id)
  assert tx == nil
end

test "borrar moneda con transacciones existentes no la elimina", %{users: {user1,user2}, money: {money1, _}} do
  Ledger.CLI.process({"alta_cuenta", user1.id, money1.id, 500})
  Ledger.CLI.process({"alta_cuenta", user2.id, money1.id, 500})
  Ledger.CLI.process({"realizar_transferencia", user1.id, user2.id, money1.id, 100})
  Ledger.CLI.process({"borrar_moneda", money1.id})
  money = Repo.get(Money, money1.id)
  assert money != nil
end

test "editar usuario inexistente no altera la BD" do
  Ledger.CLI.process({"editar_usuario", 9999, "nuevo_nombre"})
  # Asegurarse que no se insertó un usuario nuevo por error
  user = Repo.get(Users, 9999)
  assert user == nil
end

test "borrar usuario con transacciones no permite eliminarlo", %{users: {user1, user2}, money: {money1, _}} do
  # Primero, crear una transacción asociada al usuario
  Ledger.CLI.process({"crear_usuario", "Gloria", "1995-05-05"})
  user = Repo.get_by(Users, username: "Gloria")
  Ledger.CLI.process({"alta_cuenta", user.id, money1.id, 500})
  Ledger.CLI.process({"alta_cuenta", user1.id, money1.id, 500})
  Ledger.CLI.process({"realizar_transferencia", user.id, user1.id, money1.id, 100})
  # Intentar borrar al usuario con transacciones
  result = Ledger.CLI.process({"borrar_usuario", user.id})

  # Verificar que devuelve un error y no borra al usuario
  assert Repo.get(Users, user.id) != nil
end
test "realizar swap exitoso actualiza transacciones", %{users: {user, _}, money: {money1, money2}} do
  # Primero, dar alta de cuenta con ambas monedas
  Ledger.TransactionOperations.create_high_account(user.id, money1.id, 100)
  Ledger.TransactionOperations.create_high_account(user.id, money2.id, 50)

  # Ejecutar swap
  result = Ledger.CLI.process({"realizar_swap", user.id, money1.id, money2.id, 30})
  tx = Repo.one(from t in Transaction,
                where: t.origin_account_id == ^user.id and t.type == "swap",
                limit: 1)
  assert tx =! nil
end

test "swap falla si no hay saldo suficiente", %{users: {user, _}, money: {money1, money2}} do
  # Alta de cuenta con poco saldo
  Ledger.TransactionOperations.create_high_account(user.id, money1.id, 10)

  # Intentar swap mayor al saldo
  result = Ledger.CLI.process({"realizar_swap", user.id, money1.id, money2.id, 50})

  # Verificar que no se haya creado ninguna transacción de tipo swap para ese usuario
  tx = Repo.one(from t in Transaction,
                where: t.origin_account_id == ^user.id and t.type == "swap",
                limit: 1)
  assert tx == nil
end

test "swap falla si no hay alta de cuenta", %{users: {user, _}, money: {money1, money2}} do
  # No damos alta de cuenta
  result = Ledger.CLI.process({"realizar_swap", user.id, money1.id, money2.id, 10})
   tx = Repo.one(from t in Transaction,
                where: t.origin_account_id == ^user.id and t.type == "swap",
                limit: 1)
  assert tx == nil
end
test "crear usuario con nombre mínimo y máximo permitido" do
      Ledger.CLI.process({"crear_usuario", "abc", "2000-01-01"})
      Ledger.CLI.process({"crear_usuario", "abcd", "2000-01-01"})
      user_min = Repo.get_by(Users, username: "abc")
      user_max = Repo.get_by(Users, username: "abcd")
      assert user_min != nil
      assert user_max != nil
    end

    test "crear moneda con precio 0 y muy grande" do
      Ledger.CLI.process({"crear_moneda", "ZERO", 0})
      Ledger.CLI.process({"crear_moneda", "BIG", 1_000_000_000})
      money_zero = Repo.get_by(Money, name: "ZERO")
      money_big = Repo.get_by(Money, name: "BIG")
      assert money_zero != nil and money_zero.price == 0
      assert money_big != nil and money_big.price == 1_000_000_000
    end

test "undo alta_cuenta funciona correctamente", %{users: {user1, _}, money: {money1, _}} do
  {:ok, _msg} = Ledger.TransactionOperations.create_high_account(user1.id, money1.id, 100)

  tx = Repo.one(
    from t in Transaction,
      where: t.origin_account_id == ^user1.id and t.origin_currency_id == ^money1.id,
      order_by: [desc: t.inserted_at],
      limit: 1
  )

  result = Ledger.CLI.process({"deshacer_transaccion", to_string(tx.id)})
  assert result == :ok
  assert Repo.get(Transaction, tx.id) == nil

end
test "undo de transferencia elimina correctamente la transacción", %{users: {user1, user2}, money: {usd, _}} do
  # Dar alta de cuenta para que haya saldo suficiente
  {:ok, _msg} = Ledger.TransactionOperations.create_high_account(user1.id, usd.id, 200)
  {:ok, _msg} = Ledger.TransactionOperations.create_high_account(user2.id, usd.id, 200)
  # Realizar la transferencia
  Ledger.CLI.process({"realizar_transferencia", user1.id, user2.id, usd.id, 50})

  tx = Repo.one(
    from t in Transaction,
      where: t.origin_account_id == ^user1.id and t.origin_currency_id == ^usd.id,
      order_by: [desc: t.inserted_at],
      limit: 1
  )

  result = Ledger.CLI.process({"deshacer_transaccion", to_string(tx.id)})
  assert result == :ok

  assert Repo.get(Transaction, tx.id) == nil
end

test "undo de swap elimina correctamente la transacción", %{users: {user1, _}, money: {usd, btc}} do
    Ledger.TransactionOperations.create_high_account(user1.id, usd.id, 100)
    Ledger.TransactionOperations.create_high_account(user1.id, btc.id, 1)

    Ledger.CLI.process({"realizar_swap", user1.id, usd.id, btc.id, 50})


    tx = Repo.one(
      from t in Transaction,
        where: t.origin_account_id == ^user1.id and t.origin_currency_id == ^usd.id,
        order_by: [desc: t.inserted_at],
        limit: 1
    )

    result = Ledger.CLI.process({"deshacer_transaccion", to_string(tx.id)})
    assert result == :ok

    assert Repo.get(Transaction, tx.id) == nil
  end

  test "undo de transacción inexistente muestra mensaje de error", %{users: {user1, _}, money: {usd, _}} do
    output = capture_io(fn ->
      Ledger.CLI.process({"deshacer_transaccion", "999999"})
    end)
    assert output =~"{:error, undo: Transacción no encontrada}\n"
  end

  test "ver_usuario muestra información correcta", %{users: {user1, _}, money: {money1, _}} do
    Ledger.CLI.process({"crear_usuario", "Gloria", "1995-05-05"})
    user = Repo.get_by(Users, username: "Gloria")
    output = capture_io(fn -> Ledger.CLI.process({"ver_usuario", user.id}) end)
    assert output =~ "id= #{user.id}"
  end
end
   describe "decode_response/1" do
    test "devuelve string con clave y valor cuando es {:ok, body}" do
      body = [mensaje: "Operación exitosa"]
      result = Ledger.CLI.decode_response({:ok, body})
      assert result == "mensaje: Operación exitosa"
    end

    test "devuelve string con {:error, clave: valor} cuando es {:error, reason}" do
      reason = [error: "Usuario no encontrado"]
      result = Ledger.CLI.decode_response({:error, reason})
      assert result == "{:error, error: Usuario no encontrado}"
    end

    test "maneja correctamente una lista con varios pares clave-valor (usa el primero)" do
      body = [clave1: "valor1", clave2: "valor2"]
      result = Ledger.CLI.decode_response({:ok, body})
      assert result == "clave1: valor1"
    end
    test "maneja keyword con valor numérico" do
  result = Ledger.CLI.decode_response({:ok, [balance: 123.45]})
  assert result == "balance: 123.45"
end

    test "maneja keyword con atom" do
      result = Ledger.CLI.decode_response({:ok, [estado: :ok]})
      assert result == "estado: ok"
    end

  end

end
