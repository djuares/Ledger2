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
        m: :string,

        n: :string,
        b: :string,
        id: :string,

        p: :string,

        u: :string,
        d: :string,
        mo: :string,
        md: :string,
        a: :string

        ],
      aliases: [
        h: :help,
        t: :t,
        c1: :c1,
        c2: :c2,
        o: :o,
        m: :m,
        n: :n,
        b: :b,
        id: :id,
        p: :p,
        u: :u,
        d: :d,
        mo: :mo,
        md: :md,
        a: :a
      ]
    )
    {args, opts}
    |> args_to_internal_representation()
  end

  def args_to_internal_representation({["transaction"], opts}) do
    origin_account = opts[:c1] || @default[:origin_account]
    destinate_account = opts[:c2] || @default[:destinate_account]

    {"transaction", origin_account,destinate_account}
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


  def args_to_internal_representation({["create_user"], opts}) do
    username = opts[:n]
    birthdate = opts[:b]

    {"create_user", username, birthdate}
  end
  def args_to_internal_representation({["edit_user"], opts}) do
    user_id = opts[:id]
    new_name = opts[:n]

    {"edit_user", user_id, new_name}
  end
  def args_to_internal_representation({["delete_user"], opts}) do
    user_id = opts[:id]

    {"delete_user", user_id}
  end
  def args_to_internal_representation({["view_user"], opts}) do
    user_id = opts[:id]

    {"view_user", user_id}
  end


  def args_to_internal_representation({["create_money"], opts}) do
    money_name= opts[:n]
    usd_price= opts[:p]

    {"create_money", money_name, usd_price}
  end
    def args_to_internal_representation({["edit_money"], opts}) do
    money_id= opts[:id]
    new_usd_price= opts[:p]

    {"edit_money", money_id, new_usd_price}
  end
  def args_to_internal_representation({["delete_money"], opts}) do
    money_id= opts[:id]

    {"delete_money", money_id}
  end
  def args_to_internal_representation({["view_money"], opts}) do
    money_id= opts[:id]

    {"view_money", money_id}
  end


  def args_to_internal_representation({["high_account"], opts}) do
    user_id= opts[:u]
    money_id= opts[:m]

    {"high_account", user_id, money_id}
  end
  def args_to_internal_representation({["make_transfer"], opts}) do
    id_user_origin= opts[:o]
    id_user_destine= opts[:d]
    amount= opts[:a]


    {"make_transfer", id_user_origin, id_user_destine, amount}
  end
  def args_to_internal_representation({["make_swap"], opts}) do
    id_user= opts[:u]
    id_money_origin= opts[:mo]
    id_money_destine= opts[:md]
    amount= opts[:a]

    {"make_swap", id_user, id_money_origin, id_money_destine, amount}
  end
  def args_to_internal_representation({["undo_transaction"], opts}) do
    id_transaction= opts[:id]

    {"undo_transaction", id_transaction}
  end
  def args_to_internal_representation({["view_transaction"], opts}) do
    id_transaction= opts[:id]

    {"view_transaction", id_transaction}
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

        ./ledger create_user -n=<username> -b=<birth_date>
        ./ledger edit_user -id=<user-id> -n=<new-username>
        ./ledger delete_user -id=<user-id>
        ./ledger view_user -id=<user-id>

        ./ledger create_money -n=<money-name> -p=<usd-price>
        ./ledger edit_money -id=<money-id> -p=<new-usd-price>
        ./ledger delete_money -id=<money-id>
        ./ledger view_money -id=<money-id>

        ./ledger high_account -u=<user-id> -m=<money-id>
        ./ledger make_transfer -o=<user-id-origin> -d=<user-id-destine> -m=<money-id>
        ./ledger make_swap -u=<user-id> -mo=<money-id-origin> -md=<money-id-destine> -a=<amount>
        ./ledger undo_transaction -id=<transaction-id>
        ./ledger view_transaction -id=<transaction-id>

        Examples:

          ./ledger transaction -t=input_file.csv -c1=122 -o=output_file.csv

          ./ledger balance -c1=122 -m=BTC
    """)
    System.halt(0)
  end

  def process({"transaction", origin_account, destinate_account}) do
    Ledger.ListTransactions.list(origin_account, destinate_account)
    |> decode_response()
    |> IO.puts()
  end

  def process({"balance", input_file, origin_account, money_type, output_file}) do
    Ledger.ListBalance.list(input_file,origin_account,  money_type, output_file)
    |> decode_response()
    |> IO.puts()
  end

  def process({"create_user", username, birthdate}) do
    Ledger.UserOperations.create_user(username, birthdate)
    |> decode_response()
    |> IO.puts()
  end
  def process({"create_money", money_name, usd_price}) do
    Ledger.MoneyOperations.create_money(money_name, usd_price)
    |> decode_response()
    |> IO.puts()
  end
  def process({"high_account", user_id, money_id}) do
    Ledger.TransactionOperations.create_high_account(user_id, money_id)
    |> decode_response()
    |> IO.puts()
  end
  def decode_response({:ok, body}), do: body
  def decode_response({:error, reason}), do: " {:error, #{inspect(reason)}}"
end
