-- Schemas und Rohdatentabelle. Idempotent: kann beliebig oft ausgeführt werden (make db-init).

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS mart;

-- Eine Zeile pro Zeitreihe, Region, Auflösung und Zeitstempel, so wie von der SMARD-API geliefert.
CREATE TABLE IF NOT EXISTS raw.smard_observation (
    series_id  integer          NOT NULL,  -- SMARD-Filter-ID (z. B. Day-Ahead-Preis, Wind-Prognose)
    region     text             NOT NULL,  -- SMARD-Region, z. B. 'DE-LU', 'DE'
    resolution text             NOT NULL,  -- SMARD-Auflösung, z. B. 'hour', 'quarterhour'
    ts_utc     timestamptz      NOT NULL,  -- Beginn des Intervalls, UTC
    value      double precision,           -- NULL erlaubt: SMARD liefert null für fehlende Werte
    loaded_at  timestamptz      NOT NULL DEFAULT now(),
    PRIMARY KEY (series_id, region, resolution, ts_utc)  -- Upsert-Schlüssel (ON CONFLICT)
);
