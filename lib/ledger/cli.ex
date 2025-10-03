defmodule Ledger.CLI do
  @default [input_file: "data/input/trans.csv", origin_account: "0",destinate_account: "0", output_file: "data/output/default_output.csv", money_type: "0"]

  def main(argv) do
    argv
    |> parse_args
    |> process
  end

  def parse_args(argv) do
    {opts, args, _} = OptionParser.parse(
      argv,
      switches: [
        help: :boolean,
        t: :string,
        c1: :string,
        c2: :string,
        o: :string,
        m: :string
      ],
      aliases: [
        h: :help,
        t: :t,
        c1: :c1,
        c2: :c2,
        o: :o,
        m: :m
      ]
    )
    {args, opts}
    |> args_to_internal_representation()
  end

  def args_to_internal_representation({["transaction"], opts}) do
    input_file = opts[:t] || @default[:input_file]
    origin_account = opts[:c1] || @default[:origin_account]
    destinate_account = opts[:c2] || @default[:destinate_account]
    output_file = opts[:o] || @default[:output_file]

    {"transaction", input_file, origin_account,destinate_account, output_file}
  end

  def args_to_internal_representation({["balance"], opts}) do
    if is_nil(opts[:c1]) do
      IO.puts(:stderr, "Falta un argumento requerido: -c1=<cuenta>")
      System.halt(1)
    else
      input_file = opts[:t] || @default[:input_file]
      origin_account = opts[:c1]
      money_type = opts[:m] || @default[:money_type]
      output_file = opts[:o] || @default[:output_file]
      {"balance", input_file, origin_account, money_type, output_file}
    end
  end

  def args_to_internal_representation(_) do
    :help
  end

  def process(:help) do
    IO.puts("""
    usage:

        ./ledger transaction [option]

          Options:
            -t : transaction file
            -c1 : origin account
            -c2 : destinate account
            -o : output file

        ./ledger balance -c1= [option]

          Options:
            -t : transaction file
            -c1 : origin account
            -o : output file
            -m : money type

        Examples:

          ./ledger transaction -t=input_file.csv -c1=122 -o=output_file.csv

          ./ledger balance -c1=122 -m=BTC
    """)
    System.halt(0)
  end

  def process({"transaction", input_file, origin_account, destinate_account, output_file}) do
    Ledger.Transactions.list(input_file, origin_account, destinate_account, output_file)
    |> decode_response()
    |> IO.puts()
  end

  def process({"balance", input_file, origin_account, money_type, output_file}) do
    Ledger.Balance.list(input_file,origin_account,  money_type, output_file)
    |> decode_response()
    |> IO.puts()
  end

  def decode_response({:ok, body}), do: body
  def decode_response({:error, reason}), do: " {:error, #{inspect(reason)}}"
end
