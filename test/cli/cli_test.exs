
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

end
