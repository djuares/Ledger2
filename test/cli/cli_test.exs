
defmodule CliTest do
  use ExUnit.Case
  import Ledger.CLI
  use Ledger.RepoCase
  import ExUnit.CaptureIO

  alias Ledger.UserOperations
  alias Ledger.Users

  describe "commands to list" do
    test ":help returned by option parsing with -h and --help options" do
      assert parse_args(["-h",     "anything"]) == :help
      assert parse_args(["--help", "anything"]) == :help
    end
    test "transaction default" do
      assert parse_args(["transaction"]) == {"transaction","data/input/trans.csv", "0", "0", "data/output/default_output.csv" }
    end
      test "transaction with arguments c1 and files" do
      assert parse_args(["transaction", "-t=input_file", "-c1=312", "-o=output_file"]) == {"transaction", "input_file", "312", "0", "output_file"}
    end
    test "transaction with arguments c1, c2 and files" do
      assert parse_args(["transaction", "-t=input_file", "-c1=312", "-c2=133", "-o=output_file"]) == {"transaction", "input_file", "312", "133", "output_file"}
    end
    test "balance with arguments" do
      assert parse_args(["balance","-c1=312", "-m=money_type"]) == {"balance", "data/input/trans.csv", "312", "money_type", "data/output/default_output.csv"}
    end
    test "balance default" do
      assert parse_args(["balance", "-c1=312"]) ==    {"balance", "data/input/trans.csv", "312", "0","data/output/default_output.csv"}
    end
    test "Se devueelve la linea incorrecta en caso de formato incorrecto" do
      assert decode_response({:error, 1}) ==  " {:error, 1}"
    end
    end
  describe "user_commands" do
    test "create_user" do
      assert parse_args(["create_user", "-n=sofia", "-b=1999-01-01"]) ==
            {"create_user", "sofia", "1999-01-01"}
    end
    test "edit_user" do
      assert parse_args(["edit_user", "-id=312", "-n=sofia"]) ==
            {"edit_user", "312", "sofia"}
    end
    test "delete_user" do
      assert parse_args(["delete_user", "-id=312"]) ==
            {"delete_user", "312"}
    end
    test "view_user" do
      assert parse_args(["view_user", "-id=312"]) ==
            {"view_user", "312"}
    end
  end

   describe "money commands" do
    test "parse money_create" do
      assert parse_args(["create_money", "-n=Bitcoin", "-p=68000"]) ==
             {"create_money", "Bitcoin", "68000"}
    end

    test "parse edit_money" do
      assert parse_args(["edit_money", "-id=5", "-p=70000"]) ==
             {"edit_money", "5", "70000"}
    end

    test "parse delete_money" do
      assert parse_args(["delete_money", "-id=5"]) ==
             {"delete_money", "5"}
    end

    test "parse view_money" do
      assert parse_args(["view_money", "-id=5"]) ==
             {"view_money", "5"}
    end
  end

  describe "account and transaction commands" do
    test "parse high_account" do
      assert parse_args(["high_account", "-u=7", "-m=3"]) ==
             {"high_account", "7", "3"}
    end

    test "parse make_transfer" do
      assert parse_args(["make_transfer", "-o=2", "-d=5", "-a=312"]) ==
             {"make_transfer", "2", "5", "312"}
    end

    test "parse make_swap" do
      assert parse_args(["make_swap", "-u=4", "-mo=2", "-md=3", "-a=100"]) ==
             {"make_swap", "4", "2", "3", "100"}
    end

    test "parse undo_transaction" do
      assert parse_args(["undo_transaction", "-id=12"]) ==
             {"undo_transaction", "12"}
    end

    test "parse view_transaction" do
      assert parse_args(["view_transaction", "-id=12"]) ==
             {"view_transaction", "12"}
    end
  end

  describe "process/1 for create_user" do
    test "calls create_user and prints confirmation" do
      output = capture_io(fn ->
      Ledger.CLI.process({"create_user", "sofia", "2000-01-01"})
      end)

      assert String.contains?(output, "User created successfully")


      # Verificamos que realmente se insertó en la DB
      user= Repo.get_by(Users, username: "sofia")
      assert user.username == "sofia"
      assert user.birth_date == ~D[2000-01-01]
    end
  end

end
