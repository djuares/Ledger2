
defmodule CliTest do
  use ExUnit.Case
  import Ledger.CLI

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
