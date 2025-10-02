## Iniciando la Aplicación

```bash
mix deps.get
```
```bash
mix compile
```

## Base de datos con Docker
1. Levanta el servicio de base de datos:
```bash
docker-compose up -d postgres
```

2. Crea la base de datos:
```bash
mix ecto.create
```
