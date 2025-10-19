# Variables
MIX_ENV ?= dev

# Levantar contenedores de Docker
up:
	docker-compose up -d

# Parar contenedores
down:
	docker-compose down

# Instalar dependencias de Elixir
deps:
	mix deps.get

# Crear base de datos (dev o test)
db-create:
	MIX_ENV=$(MIX_ENV) mix ecto.create

# Migrar base de datos (dev o test)
db-migrate:
	MIX_ENV=$(MIX_ENV) mix ecto.migrate

# Crear las dos bases (dev y test)
db-init:
	MIX_ENV=dev mix ecto.create
	MIX_ENV=test mix ecto.create

# Migrar ambas bases (dev y test)
db-migrate-all:
	MIX_ENV=dev mix ecto.migrate
	MIX_ENV=test mix ecto.migrate

# Reset completo (drop + create + migrate) para dev y test
db-reset:
	MIX_ENV=dev mix ecto.drop
	MIX_ENV=dev mix ecto.create
	MIX_ENV=dev mix ecto.migrate
	MIX_ENV=test mix ecto.drop
	MIX_ENV=test mix ecto.create
	MIX_ENV=test mix ecto.migrate

db-seed:
	MIX_ENV=dev mix run priv/repo/seeds.exs
	MIX_ENV=test mix run priv/repo/seeds.exs

# Setup completo para un nuevo desarrollador
setup: up deps db-init db-migrate-all  db-seed
	@echo "✅ Setup completado. Ahora podés ejecutar: mix test --cover"
