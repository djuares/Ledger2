# Compilación del Ejecutable
```bash
# Genera el ejecutable
$ mix escript.build
```
# Base de datos con Docker
```bash
#1. Levanta el servicio de base de datos:
docker-compose up -d postgres
```

# Ejecución del Programa
```bash
# Ejecutar con ayuda
$ ./ledger --help
```
## Transaction
    ```bash
    $ ./ledger transaction [opciones]
    ```
    ```bash
    # Ejecutar normalmente con ruta relativa
    $ ./ledger transaction -t=<archivo.csv> -c1=<account> -c2=<account> -o=<archivo.csv>
    ```
    ```bash
    # Ruta absoluta 
    $ ./ledger transaction -t="/ruta/al/archivo/transac.csv" -c1=<account> -c2=<account> -o="/ruta/al/archivo/output.csv"
    ```
## Balance
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

#ME PARECE QUE NO VA (REVISAR)
## Base de datos dev
    2. Crea la base de datos dev:
    ```bash
    mix ecto.create
    mix ecto.migrate
    ```
## Base de datos test
    1. Crear la base de datos de test (opcional, para correr tests):
    ```bash
    MIX_ENV=test mix ecto.create
    MIX_ENV=test mix ecto.migrate

    ```
    MIX_ENV=test mix run priv/repo/seeds.exs
    2. Ejecutar test
    ```bash
    MIX_ENV=test mix test
    ```

## Abrir una consola de PostgreSQL y listar tablas
```bash
sudo  psql -U postgres -d ledger -h localhost  
\dt                                             #listar tablas
SELECT * FROM money;                            #ver respectiva tabla
SELECT * FROM users;
SELECT * FROM transactions;

```
## Abrir docker y ver bases de datos
```bash
docker exec -it ledger_postgres_1 psql -U postgres
\l                                              #listar bases de datos
```
## Poner datos iniciales

priv/repo/seeds.exs
```bash
priv/repo/seeds.exs
```
