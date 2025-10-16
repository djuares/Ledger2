defmodule Ledger.CLI do
    @default [origin_account: "0",destinate_account: "0", money_type: "0"]
  def main(argv) do
    Logger.configure(level: :info)

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

  def args_to_internal_representation({["transacciones"], opts}) do
    origin_account = opts[:c1] || @default[:origin_account]
    destinate_account = opts[:c2] || @default[:destinate_account]

    {"transacciones", origin_account,destinate_account}
  end
  def args_to_internal_representation({["balance"], opts}) do
    if is_nil(opts[:c1]) do
      IO.puts(:stderr, "Falta un argumento requerido: -c1=<cuenta>")
      System.halt(1)
    else
      origin_account = opts[:c1]
      money_type = opts[:m] || @default[:money_type]
      {"balance", origin_account, money_type}
    end
  end


  def args_to_internal_representation({["crear_usuario"], opts}) do
    username = opts[:n]
    birthdate = opts[:b]

    {"crear_usuario", username, birthdate}
  end
  def args_to_internal_representation({["editar_usuario"], opts}) do
    user_id = opts[:id]
    new_name = opts[:n]

    {"editar_usuario", user_id, new_name}
  end
  def args_to_internal_representation({["borrar_usuario"], opts}) do
    user_id = opts[:id]

    {"borrar_usuario", user_id}
  end
  def args_to_internal_representation({["ver_usuario"], opts}) do
    user_id = opts[:id]

    {"ver_usuario", user_id}
  end


  def args_to_internal_representation({["crear_moneda"], opts}) do
    money_name= opts[:n]
    usd_price= opts[:p]

    {"crear_moneda", money_name, usd_price}
  end
    def args_to_internal_representation({["editar_moneda"], opts}) do
    money_id= opts[:id]
    new_usd_price= opts[:p]

    {"editar_moneda", money_id, new_usd_price}
  end
  def args_to_internal_representation({["borrar_moneda"], opts}) do
    money_id= opts[:id]

    {"borrar_moneda", money_id}
  end
  def args_to_internal_representation({["ver_moneda"], opts}) do
    money_id= opts[:id]

    {"ver_moneda", money_id}
  end


  def args_to_internal_representation({["alta_cuenta"], opts}) do
    user_id= opts[:u]
    money_id= opts[:m]
    amount= opts[:a]

    {"alta_cuenta", user_id, money_id, amount}
  end
  def args_to_internal_representation({["realizar_transferencia"], opts}) do
    id_user_origin= opts[:o]
    id_user_destine= opts[:d]
    money_id= opts[:m]
    amount= opts[:a]


    {"realizar_transferencia", id_user_origin, id_user_destine, money_id, amount}
  end
  def args_to_internal_representation({["realizar_swap"], opts}) do
    id_user= opts[:u]
    id_money_origin= opts[:mo]
    id_money_destine= opts[:md]
    amount= opts[:a]

    {"realizar_swap", id_user, id_money_origin, id_money_destine, amount}
  end
  def args_to_internal_representation({["deshacer_transaccion"], opts}) do
    id_transaction= opts[:id]

    {"deshacer_transaccion", id_transaction}
  end
  def args_to_internal_representation({["ver_transaccion"], opts}) do
    id_transaction= opts[:id]

    {"ver_transaccion", id_transaction}
  end

  def args_to_internal_representation(_) do
    :help
  end

  def process(:help) do
    IO.puts("""
    usage:

        ./ledger transacciones [option]

          Options:
            -c1 : origin account
            -c2 : destinate account

        ./ledger balance -c1= [option]

          Options:
            -c1 : origin account
            -m : money type

        ./ledger crear_usuario -n=<username> -b=<birth_date>
        ./ledger editar_usuario -id=<user-id> -n=<new-username>
        ./ledger borrar_usuario -id=<user-id>
        ./ledger ver_usuario -id=<user-id>

        ./ledger crear_moneda -n=<money-name> -p=<usd-price>
        ./ledger editar_moneda -id=<money-id> -p=<new-usd-price>
        ./ledger borrar_moneda -id=<money-id>
        ./ledger ver_moneda -id=<money-id>

        ./ledger alta_cuenta -u=<user-id> -m=<money-id> -a=<amount>
        ./ledger realizar_transferencia -o=<user-id-origin> -d=<user-id-destine> -m=<money-id> -a=<amount>
        ./ledger realizar_swap -u=<user-id> -mo=<money-id-origin> -md=<money-id-destine> -a=<amount>
        ./ledger deshacer_transaccion -id=<transaction-id>
        ./ledger ver_transaccion -id=<transaction-id>

        Examples:

          ./ledger transacciones -c1=122

          ./ledger balance -c1=122 -m=BTC
    """)
    System.halt(0)
  end

  def process({"transacciones", origin_account, destinate_account}) do
    Ledger.ListTransactions.list(origin_account, destinate_account)
    |> decode_response()
    |> IO.puts()
  end

  def process({"balance", origin_account, money_type}) do
    Ledger.ListBalance.list(origin_account,  money_type)
    |> decode_response()
    |> IO.puts()
  end

  def process({"crear_usuario", username, birthdate}) do
    Ledger.UserOperations.create_user(username, birthdate)
    |> decode_response()
    |> IO.puts()
  end
  def process({"editar_usuario", user_id, new_name}) do
    Ledger.UserOperations.edit_user( user_id, new_name)
    |> decode_response()
    |> IO.puts()
  end
  def process({"borrar_usuario", user_id}) do
    Ledger.UserOperations.delete_user(user_id)
    |> decode_response()
    |> IO.puts()
  end
  def process({"ver_usuario", user_id}) do
    Ledger.UserOperations.view_user(user_id)
    |> decode_response()
    |> IO.puts()
  end

  def process({"crear_moneda", money_name, usd_price}) do
    Ledger.MoneyOperations.create_money(money_name, usd_price)
    |> decode_response()
    |> IO.puts()
  end
  def process({"editar_moneda", money_id, new_usd_price}) do
    Ledger.MoneyOperations.edit_money(money_id, new_usd_price)
    |> decode_response()
    |> IO.puts()
  end
  def process( {"borrar_moneda", money_id}) do
    Ledger.MoneyOperations.delete_money(money_id)
    |> decode_response()
    |> IO.puts()
  end
  def process({"ver_moneda", money_id}) do
    Ledger.MoneyOperations.show_money(money_id)
    |> decode_response()
    |> IO.puts()
  end


  def process({"alta_cuenta", user_id, money_id, amount}) do
    Ledger.TransactionOperations.create_high_account(user_id, money_id, amount)
    |> decode_response()
    |> IO.puts()
  end
  def process( {"realizar_transferencia", id_user_origin, id_user_destine, money_id, amount}) do
    Ledger.TransactionOperations.transfer( id_user_origin, id_user_destine, money_id, amount)
    |> decode_response()
    |> IO.puts()
  end
  def process({"realizar_swap", id_user, id_money_origin, id_money_destine, amount}) do
    Ledger.TransactionOperations.swap(id_user, id_money_origin, id_money_destine, amount)
    |> decode_response()
    |> IO.puts()
  end
  def process( {"deshacer_transaccion", id_transaction}) do
    Ledger.TransactionOperations.undo_transaction(id_transaction)
    |> decode_response()
    |> IO.puts()
  end
  def process({"ver_transaccion", id_transaction}) do
    Ledger.TransactionOperations.show_transaction(id_transaction)
    |> decode_response()
    |> IO.puts()
  end

  def decode_response({:ok, body}) do
  key = Keyword.keys(body) |> hd()
  value = Keyword.values(body) |> hd()
  "#{key}: #{value}"
end

def decode_response({:error, reason}) do
  key = Keyword.keys(reason) |> hd()
  value = Keyword.values(reason) |> hd()
  "{:error, #{key}: #{value}}"
end

end
