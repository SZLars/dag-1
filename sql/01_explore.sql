
-- 20556 · Mandag · Version 1.0

-- 1. Dataundersøgelse

-- antal rækker
SELECT COUNT(*) AS antal_ture
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

-- se kolonner og datatyper
DESCRIBE
SELECT *
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

-- se nogle af rækkerne
SELECT *
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')
LIMIT 10;

-- find første og sidste pickup tidspunkt
SELECT
    MIN(tpep_pickup_datetime) AS foerste_pickup,
    MAX(tpep_pickup_datetime) AS sidste_pickup
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

-- antal forskellige pickup steder
SELECT COUNT(DISTINCT PULocationID) AS antal_pickup_steder
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

-- se hvilke pickup steder der bliver brugt mest
SELECT
    PULocationID,
    COUNT(*) AS antal_ture
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')
GROUP BY PULocationID
ORDER BY antal_ture DESC
LIMIT 10;

-- Her kan jeg se hvor meget data der er, hvilke kolonner der findes,
-- og hvilken periode dataen kommer fra.


-- 2. Eget analysespørgsmål

-- hvilke pickup steder har flest ture?
SELECT
    PULocationID,
    COUNT(*) AS antal_ture,
    ROUND(AVG(trip_distance), 2) AS gennemsnit_distance
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')
GROUP BY PULocationID
ORDER BY antal_ture DESC
LIMIT 10;

-- En række viser et pickup sted og hvor mange ture der startede der.
-- Den viser også den gennemsnitlige distance.


-- 3. Sammenhæng mellem kilderne

-- se zone filen
SELECT *
FROM read_csv_auto('data/raw/taxi_zone_lookup.csv')
LIMIT 10;

-- se kolonnerne i zone filen
DESCRIBE
SELECT *
FROM read_csv_auto('data/raw/taxi_zone_lookup.csv');

-- PULocationID i taxi data passer sammen med LocationID i zone filen.

SELECT
    t.PULocationID,
    z.Borough,
    z.Zone,
    COUNT(*) AS antal_ture
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet') t
LEFT JOIN read_csv_auto('data/raw/taxi_zone_lookup.csv') z
    ON t.PULocationID = z.LocationID
GROUP BY
    t.PULocationID,
    z.Borough,
    z.Zone
ORDER BY antal_ture DESC
LIMIT 20;

-- se om der er ture som ikke har en zone
SELECT COUNT(*) AS mangler_zone
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet') t
LEFT JOIN read_csv_auto('data/raw/taxi_zone_lookup.csv') z
    ON t.PULocationID = z.LocationID
WHERE z.LocationID IS NULL;

-- tjek antal rækker før join
SELECT COUNT(*) AS foer_join
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet');

-- tjek antal rækker efter join
SELECT COUNT(*) AS efter_join
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet') t
LEFT JOIN read_csv_auto('data/raw/taxi_zone_lookup.csv') z
    ON t.PULocationID = z.LocationID;

-- Hvis antal før og efter er det samme, har joinet ikke lavet ekstra rækker.


-- prøv INNER JOIN i stedet for LEFT JOIN
SELECT
    z.Borough,
    z.Zone,
    COUNT(*) AS antal_ture
FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet') t
INNER JOIN read_csv_auto('data/raw/taxi_zone_lookup.csv') z
    ON t.PULocationID = z.LocationID
GROUP BY
    z.Borough,
    z.Zone
ORDER BY antal_ture DESC
LIMIT 20;

-- INNER JOIN fjerner ture hvis der ikke findes en zone der passer.
-- LEFT JOIN beholder dem.


-- 4. Dokumentation

-- DuckDB sider jeg brugte:
-- read_parquet
-- read_csv_auto
-- GROUP BY
-- COUNT og AVG
-- JOIN
-- DESCRIBE

-- Resten af dokumentationen skal skrives i docs/architecture.md

