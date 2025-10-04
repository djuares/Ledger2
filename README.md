# Compilación del Ejecutable

```bash
# Genera el ejecutable
$ mix escript.build
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
# Iniciando la Aplicación

```bash
mix deps.get
```
```bash
mix compile
```

# Base de datos con Docker
1. Levanta el servicio de base de datos:
```bash
docker-compose up -d postgres
```
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
2. Ejecutar test
```bash
MIX_ENV=test mix test
```

## Abrir una consola de PostgreSQL

```bash
sudo  psql -U postgres -d ledger_test -h localhost
\dt
```

```bash
docker exec -it ledger_postgres_1 psql -U postgres
\l
```