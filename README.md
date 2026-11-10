# Negative Strompreise in Deutschland

Wann wird Strom am Day-Ahead-Markt negativ bepreist, und lässt sich das **vor der Auktion** vorhersagen?

## Fragestellung
Binäre Klassifikation pro Stunde: Ist der Day-Ahead-Preis (Gebotszone DE-LU) **< 0 €/MWh**?
Als Input dienen ausschließlich Informationen, die vor der Day-Ahead-Auktion bekannt sind:

- Prognosen für Netzlast, Wind- und PV-Erzeugung (Day-Ahead)
- Kalendermerkmale (Stunde, Wochentag, Feiertage, …)
- Preis-Lags ≥ 24 h

Realisierte Werte und kürzere Preis-Lags werden bewusst **nicht** als Features verwendet (kein Datenleck).

## Daten
[SMARD](https://www.smard.de/) (Bundesnetzagentur), abgerufen über die SMARD-API (`chart_data`-Endpunkte), Zeitraum 2023–2025.

## Architektur

```
SMARD-API ──► raw ──► staging ──► mart ──► Modell
              │        │           │
              │        │           └─ breite Feature-Tabelle, eine Zeile pro Stunde
              │        └─ typisiert, dedupliziert, auf Stunden aggregiert
              └─ API-Antworten 1:1 (raw.smard_observation)
```

- Python für Ingestion, Transformation und Modellierung, PostgreSQL 16 (Docker) als Datenhaltung
- Alle Zeitstempel in UTC (`timestamptz`), Umrechnung nach `Europe/Berlin` erst in der Analyse
- Ingestion idempotent (Upsert), mit Retry bei API-Fehlern

### Umstellung auf 15-Minuten-Auflösung
Seit dem Liefertag 01.10.2025 wird der Day-Ahead-Markt in 15-Minuten-Produkten gehandelt. Für eine einheitliche Zeitreihe wird in `staging` auf Stunden aggregiert:

- **Preis:** Ab 01.10.2025 ist der Stundenpreis das arithmetische Mittel der vier Viertelstundenpreise.
- **Label:** Eine Stunde gilt als negativ, wenn das Stundenmittel < 0 €/MWh ist.
- **Begründung:** Das ist konsistent mit den stündlichen Preisen von 2023 bis 09/2025. Eine andere Definition (z. B. „mindestens eine Viertelstunde negativ“) würde einen künstlichen Bruch in der Zielvariable erzeugen.
- **Robustheitscheck:** Zusätzlich wird ausgewertet, in wie vielen Stunden mindestens eine Viertelstunde negativ war.

## Modellierung
- Baselines: Residuallast-Schwelle, logistische Regression
- Hauptmodell: LightGBM
- Zeitbasierter Split: Training 2023–2024, Test 2025
- Hauptmetrik: PR-AUC (unbalancierte Klassen)

## Setup

Voraussetzungen: [Docker](https://docs.docker.com/get-docker/) (inkl. Docker Compose), [uv](https://docs.astral.sh/uv/), GNU Make.

```bash
cp .env.example .env        # Zugangsdaten anpassen
uv sync                     # Python 3.12 + Abhängigkeiten
uv run pre-commit install   # ruff als Git-Hook
make up                     # PostgreSQL starten (Schemas werden beim ersten Start angelegt)
make test                   # Smoke-Test der Datenbank
```

Weitere Befehle: `make help`.

## Ergebnisse
> TODO

## Limitationen
> TODO

## Lizenz / Datenquelle
Daten: Bundesnetzagentur | SMARD.de, Lizenz [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
