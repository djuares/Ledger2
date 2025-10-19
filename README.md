# Ejecución de la Aplicación
```bash
$ make setup
```

# Ejecución del Programa
```bash
# Ejecutar con ayuda
$ ./ledger --help
```
## Comando tp1: Transacciones y balance
    ```bash
    $ ./ledger transaction [opciones]
    ```
    ```bash
    $ ./ledger transaction -c1=<account> -c2=<account> 
    ```
    ```bash
    # Ruta absoluta 
    $ ./ledger transaction -t="/ruta/al/archivo/transac.csv" -c1=<account> -c2=<account> -o="/ruta/al/archivo/output.csv"
    ```
    ```bash
    $ ./ledger balance -c1=<account> [opcion]
    ```
    ```bash
    $ ./ledger balance -t=<archivo.csv> -c1=<account> -o=<archivo.csv> -m=<money_type>
    ```

# Ejecutar tests
    ```bash
    $ mix test 
    ```
    Test coverage
    ```bash
    $ mix test --cover
    ```
