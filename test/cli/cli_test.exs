defmodule CliTest do
  use ExUnit.Case
  import Ledger.CLI
  use Ledger.RepoCase
  import ExUnit.CaptureIO

  alias Ledger.{Users, Money}

  describe "parse_args/1" do
    test "help options return :help" do
      assert parse_args(["-h", "anything"]) == :help
      assert parse_args(["--help", "anything"]) == :help
    end

    test "transaction default" do
      assert parse_args(["transacciones"]) == {"transacciones", "0", "0"}
    end

    test "transaction with c1" do
      assert parse_args(["transacciones", "-c1=312"]) == {"transacciones", "312", "0"}
    end

    test "transaction with c1, c2" do
      assert parse_args(["transacciones", "-c1=312", "-c2=133"]) == {"transacciones", "312", "133"}
    end

    test "balance with arguments" do
      assert parse_args(["balance", "-c1=312", "-m=BTC"]) == {"balance", "312", "BTC"}
    end

    test "balance default money_type" do
      assert parse_args(["balance", "-c1=312"]) == {"balance", "312", "0"}
    end

    test "invalid format returns :help" do
      assert parse_args(["foo"]) == :help
    end
  end

  describe "user commands parse_args/1" do
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

  describe "money commands parse_args/1" do
    test "create_money" do
      assert parse_args(["crear_moneda", "-n=Bitcoin", "-p=68000.0"]) ==
              {"crear_moneda", "Bitcoin", "68000.0"}
    end

    test "edit_money" do
      assert parse_args(["editar_moneda", "-id=5", "-p=7000.0"]) ==
              {"editar_moneda", "5", "7000.0"}
    end

    test "delete_money" do
      assert parse_args(["borrar_moneda", "-id=5"]) ==
             {"borrar_moneda", "5"}
    end

    test "view_money" do
      assert parse_args(["ver_moneda", "-id=5"]) ==
             {"ver_moneda", "5"}
    end
  end

  describe "account and transaction commands parse_args/1" do
    test "alta_cuenta" do
      assert parse_args(["alta_cuenta", "-u=7", "-m=3", "-a=600"]) ==
             {"alta_cuenta", "7", "3", "600"}
    end

    test "realizar_transferencia" do
      assert parse_args(["realizar_transferencia", "-o=2", "-d=5", "-m=BTC", "-a=312"]) ==
             {"realizar_transferencia", "2", "5", "BTC", "312"}
    end

    test "realizar_swap" do
      assert parse_args(["realizar_swap", "-u=4", "-mo=2", "-md=3", "-a=100"]) ==
             {"realizar_swap", "4", "2", "3", "100"}
    end

    test "deshacer_transaccion" do
      assert parse_args(["deshacer_transaccion", "-id=12"]) ==
             {"deshacer_transaccion", "12"}
    end

    test "ver_transaccion" do
      assert parse_args(["ver_transaccion", "-id=12"]) ==
             {"ver_transaccion", "12"}
    end
  end



    test "edit_user updates DB" do
      user = Repo.insert!(%Users{username: "ana", birth_date: ~D[1995-05-05]})
      output = capture_io(fn ->
        Ledger.CLI.process({"editar_usuario", Integer.to_string(user.id), "anna"})
      end)
      assert String.contains?(output, "editar_usuario: Usuario editado correctamente\n")

      updated_user = Repo.get!(Users, user.id)
      assert updated_user.username == "anna"
    end

    

end
