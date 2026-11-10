# CLAUDE.md

Kontext für Claude-Code-Sessions in diesem Repo.

## Projekt
Vorhersage negativer Day-Ahead-Strompreise in Deutschland. Öffentliches Portfolio-Repo, muss professionell und reproduzierbar sein.

- **Daten:** SMARD (Bundesnetzagentur), SMARD-API (`chart_data`-Endpunkte), 2023–2025, stündlich:
  Day-Ahead-Preis (DE-LU), Netzlast, Wind- und PV-Erzeugung, jeweils Day-Ahead-Prognose und realisiert.
- **Pipeline:** Python → PostgreSQL 16 (Docker) mit drei Schemas:
  - `raw`: API-Antworten 1:1 (`raw.smard_observation`)
  - `staging`: typisiert, dedupliziert, auf Stunden aggregiert
  - `mart`: breite Feature-Tabelle, eine Zeile pro Stunde
- **Ziel:** binäre Klassifikation „Preis < 0“ pro Stunde.
- **Features:** nur Informationen, die vor der Day-Ahead-Auktion bekannt sind: Last-, Wind- und PV-Prognosen, Kalender, Preis-Lags ≥ 24h.
- **Modelle:** Baselines (Residuallast-Schwelle, logistische Regression), danach LightGBM.
- **Evaluation:** zeitbasierter Split, Train 2023–2024, Test 2025. Hauptmetrik PR-AUC.

## Feste Designentscheidungen
- **Zeit:** Alle Zeitstempel in UTC speichern (`timestamptz`). Erst in der Analyse nach `Europe/Berlin` umrechnen (Zeitumstellung beachten: 23- bzw. 25-Stunden-Tage).
- **15-Minuten-Umstellung:** Seit Liefertag 01.10.2025 ist der Day-Ahead-Markt auf 15-Minuten-Auflösung umgestellt. In `staging` wird auf Stunden aggregiert; die Methode wird in der README dokumentiert.
- **Kein Datenleck:** Realisierte Werte und Preis-Lags < 24h sind **keine** Modell-Features (realisierte Werte nur für Analyse/Evaluation).
- **Ingestion:** idempotent (Upsert über den PK von `raw.smard_observation`), Retry bei API-Fehlern, `logging` statt `print`.
- **Schlank halten:** keine unnötigen Abstraktionen.

## Struktur
- `sql/`: DDL, nummeriert (`01_…`), idempotent (`IF NOT EXISTS`). Wird beim ersten DB-Start automatisch ausgeführt (`docker-entrypoint-initdb.d`), danach per `make db-init`.
- `src/negative_strompreise/`: Python-Paket (`db.py`: `get_engine()` aus `.env`).
- `tests/`: pytest; DB-Tests werden übersprungen, wenn keine DB erreichbar ist.
- `notebooks/`, `reports/figures/`, `data/` (Daten nicht versionieren).

## Befehle
```bash
cp .env.example .env   # einmalig (macht `make up` auch automatisch)
uv sync                # Abhängigkeiten installieren
make up                # Postgres starten, wartet bis healthy
make db-init           # SQL-Dateien erneut anwenden
make db-shell          # psql
make lint              # ruff check + format --check
make format            # ruff auto-fix + format
make test              # pytest
make down              # DB stoppen (Volume bleibt)
make ingest / transform / train / all   # noch Platzhalter
```
DB-Port lokal: `POSTGRES_PORT` aus `.env` (Default 5433).
