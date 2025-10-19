# Ejecución de la Aplicación
```bash
$ make setup
```

# Ejecución del Programa
```bash
# Ejecutar con ayuda
$ ./ledger --help
```
## Comando tp1
    ```bash
    $ ./ledger transaction [opciones]
    
    $ ./ledger transaction -c1=<account> -c2=<account> 

    $ ./ledger balance -c1=<account> [opcion]

    $ ./ledger balance -c1=<account> -m=<money_type>
    ```

## Comandos tp2
    ```bash
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
    ```

# Ejecutar tests
    ```bash
    $ mix test 

    #Test coverage

    $ mix test --cover
    ```
