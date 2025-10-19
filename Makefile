# Variables
MIX_ENV ?= dev

# Levantar contenedor de Postgres
up:
	docker-compose up -d

# Parar los contenedores
down:
	docker-compose down

# Crear base de datos (para dev o test)
db-create:
	MIX_ENV=$(MIX_ENV) mix ecto.create

# Migrar base de datos (para dev o test)
db-migrate:
	MIX_ENV=$(MIX_ENV) mix ecto.migrate

# Crear las dos bases (dev y test)
db-init:
	MIX_ENV=dev mix ecto.create
	MIX_ENV=test mix ecto.create

# Reset completo (borra y recrea)
db-reset:
	MIX_ENV=dev mix ecto.drop
	MIX_ENV=dev mix ecto.create
	MIX_ENV=dev mix ecto.migrate
	MIX_ENV=test mix ecto.drop
	MIX_ENV=test mix ecto.create
	MIX_ENV=test mix ecto.migrate
