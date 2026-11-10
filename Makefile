-include .env
export

COMPOSE := docker compose
PSQL    := $(COMPOSE) exec -T db psql -v ON_ERROR_STOP=1 -U $(POSTGRES_USER) -d $(POSTGRES_DB)

.PHONY: help up down db-shell db-init lint format test ingest transform train all

help: ## Verfügbare Targets anzeigen
	@grep -hE '^[a-zA-Z_-]+:.*## ' Makefile | awk -F':.*## ' '{printf "  %-10s %s\n", $$1, $$2}'

up: ## Postgres starten und warten, bis healthy (legt .env aus .env.example an, falls nötig)
	@test -f .env || { cp .env.example .env && echo ".env aus .env.example erstellt."; }
	$(COMPOSE) up -d --wait

down: ## Postgres stoppen (Volume bleibt erhalten)
	$(COMPOSE) down

db-shell: ## psql-Shell in der Datenbank
	$(COMPOSE) exec db psql -U $(POSTGRES_USER) -d $(POSTGRES_DB)

db-init: ## Alle SQL-Dateien in sql/ (erneut) anwenden – idempotent
	@for f in sql/*.sql; do echo "-> $$f"; $(PSQL) -f /docker-entrypoint-initdb.d/$$(basename $$f) || exit 1; done

lint: ## ruff lint + Format-Check
	uv run ruff check .
	uv run ruff format --check .

format: ## Code mit ruff formatieren
	uv run ruff check --fix .
	uv run ruff format .

test: ## pytest
	uv run pytest

ingest: ## SMARD -> raw (noch nicht implementiert)
	@echo "TODO: ingest ist noch nicht implementiert."

transform: ## raw -> staging -> mart (noch nicht implementiert)
	@echo "TODO: transform ist noch nicht implementiert."

train: ## Baselines + LightGBM (noch nicht implementiert)
	@echo "TODO: train ist noch nicht implementiert."

all: up ingest transform train ## Komplette Pipeline
