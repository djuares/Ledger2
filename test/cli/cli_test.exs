
defmodule CliTest do
  import Ledger.CLI
  use Ledger.RepoCase
  import ExUnit.CaptureIO

  alias Ledger.{TransactionOperations, Transaction, Repo, Users, Money, UserOperations, MoneyOperations}

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
    test "Se devueelve la linea incorrecta en caso de formato incorrecto" do
      assert decode_response({:error, 1}) ==  " {:error, 1}"
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

    test "parse undo_transaction" do
      assert parse_args(["deshacer_transaccion", "-id=12"]) ==
             {"deshacer_transaccion", "12"}
    end

    test "parse view_transaction" do
      assert parse_args(["ver_transaccion", "-id=12"]) ==
             {"ver_transaccion", "12"}
    end
  end

    describe "process/1 user commands" do
    test "crear_usuario" do
      output = capture_io(fn ->
        Ledger.CLI.process({"crear_usuario", "sofia", "2000-01-01"})
      end)

      assert String.contains?(output, "crear_usuario: Usuario creado correctamente")

      user = Repo.get_by!(Users, username: "sofia")
      assert user.username == "sofia"
      assert user.birth_date == ~D[2000-01-01]
    end

    test "editar_usuario" do
      user = Repo.insert!(%Users{username: "ana", birth_date: ~D[1995-05-05]})
      output = capture_io(fn ->
        Ledger.CLI.process({"editar_usuario", Integer.to_string(user.id), "anna"})
      end)

      assert String.contains?(output, "editar_usuario: Usuario editado correctamente")

      updated_user = Repo.get!(Users, user.id)
      assert updated_user.username == "anna"
    end

    test "borrar_usuario" do
      user = Repo.insert!(%Users{username: "carlos", birth_date: ~D[1990-01-01]})
      output = capture_io(fn ->
        Ledger.CLI.process({"borrar_usuario", Integer.to_string(user.id)})
      end)

      assert String.contains?(output, "borrar_usuario: Usuario borrado correctamente\n")
      assert Repo.get(Users, user.id) == nil
    end

      test "ver_usuario" do
        {:ok, user} = Ledger.UserOperations.create_user("sofia", "2000-01-01")
        {:ok, result} = Ledger.UserOperations.view_user(user.id)

        assert result =~ "username: sofia"
        assert result =~ "birth_date: 2000-01-01"
      end

  end
  describe "process/1 money commands" do
    test "crear_moneda" do
      output = capture_io(fn ->
        Ledger.CLI.process({"crear_moneda", "BTC", "50000.0"})
      end)
      assert String.contains?(output, "crear_moneda: Moneda creada correctamente")
    end

    test "editar_moneda" do
      {:ok, money} = MoneyOperations.create_money("ETH", "3000.0")
      output = capture_io(fn ->
        Ledger.CLI.process({"editar_moneda", Integer.to_string(money.id), "3500.0"})
      end)
      assert String.contains?(output, "editar_moneda: Moneda editada correctamente")
    end

    test "borrar_moneda" do
      {:ok, money} = MoneyOperations.create_money("DOGE", "0.1")
      output = capture_io(fn ->
        Ledger.CLI.process({"borrar_moneda", Integer.to_string(money.id)})
      end)
      assert String.contains?(output, "borrar_moneda: Moneda eliminada correctamente")
    end

    test "ver_moneda" do
      {:ok, money} = MoneyOperations.create_money("LTC", "150.0")
      output = capture_io(fn ->
        Ledger.CLI.process({"ver_moneda", Integer.to_string(money.id)})
      end)
      assert String.contains?(output, "ver_moneda: #{money.name}")
    end
  end

  describe "process/1 account and transaction commands" do
    setup do
      user = Repo.insert!(%Users{username: "juan", birth_date: ~D[1990-01-01]})
      {:ok, user: user}
    end

    test "alta_cuenta", %{user: user} do
      {:ok, money} = MoneyOperations.create_money("BTC", "50000.0")
      output = capture_io(fn ->
        Ledger.CLI.process({"alta_cuenta", Integer.to_string(user.id), Integer.to_string(money.id), "100"})
      end)
      assert String.contains?(output, "alta_cuenta: Cuenta creada correctamente")
    end

    test "realizar_transferencia", %{user: user} do
      {:ok, money} = MoneyOperations.create_money("ETH", "3000.0")
      recipient = Repo.insert!(%Users{username: "ana", birth_date: ~D[1995-05-05]})
      TransactionOperations.create_high_account(user.id, money.id, "100")
      output = capture_io(fn ->
        Ledger.CLI.process({"realizar_transferencia", Integer.to_string(user.id), Integer.to_string(recipient.id), Integer.to_string(money.id), "50"})
      end)
      assert String.contains?(output, "realizar_transferencia: Transferencia realizada correctamente")
    end

    test "realizar_swap", %{user: user} do
      {:ok, btc} = MoneyOperations.create_money("BTC", "50000.0")
      {:ok, eth} = MoneyOperations.create_money("ETH", "3000.0")
      TransactionOperations.create_high_account(user.id, btc.id, "10")
      output = capture_io(fn ->
        Ledger.CLI.process({"realizar_swap", Integer.to_string(user.id), Integer.to_string(btc.id), Integer.to_string(eth.id), "5"})
      end)
      assert String.contains?(output, "realizar_swap: Swap realizado correctamente")
    end

    test "deshacer_transaccion" do
      {:ok, tx} = TransactionOperations.transfer(1, 2, 1, "50") # IDs de ejemplo
      output = capture_io(fn ->
        Ledger.CLI.process({"deshacer_transaccion", Integer.to_string(tx.id)})
      end)
      assert String.contains?(output, "deshacer_transaccion: Transacción deshecha correctamente")
    end

    test "ver_transaccion" do
      {:ok, tx} = TransactionOperations.transfer(1, 2, 1, "50")
      output = capture_io(fn ->
        Ledger.CLI.process({"ver_transaccion", Integer.to_string(tx.id)})
      end)
      assert String.contains?(output, "ver_transaccion: Transacción")
    end
  end
end
