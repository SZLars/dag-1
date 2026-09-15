-- 20556 · Tirsdag · fact_trip og analysequeries
-- Kør først: sql/02_dimensions.sql

CREATE OR REPLACE TABLE fact_trip AS
SELECT
    ROW_NUMBER() OVER () AS trip_key,
    t.PULocationID AS pickup_zone_key,
    t.DOLocationID AS dropoff_zone_key,

    CAST(
        strftime(CAST(t.tpep_pickup_datetime AS DATE), '%Y%m%d')
        AS INTEGER
    ) AS pickup_date_key,

    CAST(
        strftime(CAST(t.tpep_dropoff_datetime AS DATE), '%Y%m%d')
        AS INTEGER
    ) AS dropoff_date_key,

    t.passenger_count,
    t.trip_distance,
    t.fare_amount,
    t.total_amount,
    t.tpep_pickup_datetime,
    t.tpep_dropoff_datetime

FROM read_parquet(
    'data/raw/yellow_tripdata_2025-01.parquet'
) AS t;


-- Kontrol af antal fact-rækker og teknisk nøgle

SELECT
    COUNT(*) AS fact_rækker,
    COUNT(DISTINCT trip_key) AS unikke_trip_nøgler
FROM fact_trip;


-- Kontrol: fact skal have samme antal rækker som raw-data

SELECT
    (SELECT COUNT(*)
     FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet'))
        AS raw_rækker,

    (SELECT COUNT(*)
     FROM fact_trip)
        AS fact_rækker;


-- Kontrol af manglende pickup-zone

SELECT COUNT(*) AS mangler_pickup_zone
FROM fact_trip AS f
LEFT JOIN dim_zone AS z
    ON f.pickup_zone_key = z.zone_key
WHERE z.zone_key IS NULL;


-- Kontrol af manglende dropoff-zone

SELECT COUNT(*) AS mangler_dropoff_zone
FROM fact_trip AS f
LEFT JOIN dim_zone AS z
    ON f.dropoff_zone_key = z.zone_key
WHERE z.zone_key IS NULL;


-- Kontrol af manglende pickup-dato

SELECT COUNT(*) AS mangler_pickup_date
FROM fact_trip AS f
LEFT JOIN dim_date AS d
    ON f.pickup_date_key = d.date_key
WHERE d.date_key IS NULL;


-- Kontrol af manglende dropoff-dato

SELECT COUNT(*) AS mangler_dropoff_date
FROM fact_trip AS f
LEFT JOIN dim_date AS d
    ON f.dropoff_date_key = d.date_key
WHERE d.date_key IS NULL;


-- Kontrol af kardinalitet:
-- joins til entydige dimensioner må ikke skabe flere fact-rækker

SELECT
    (SELECT COUNT(*) FROM fact_trip) AS fact_rækker,

    COUNT(*) AS rækker_efter_alle_joins

FROM fact_trip AS f

LEFT JOIN dim_zone AS pickup_z
    ON f.pickup_zone_key = pickup_z.zone_key

LEFT JOIN dim_zone AS dropoff_z
    ON f.dropoff_zone_key = dropoff_z.zone_key

LEFT JOIN dim_date AS pickup_d
    ON f.pickup_date_key = pickup_d.date_key

LEFT JOIN dim_date AS dropoff_d
    ON f.dropoff_date_key = dropoff_d.date_key;


-- Analysequery 1:
-- antal ture og gennemsnitlig distance pr. pickup-borough og måned

SELECT
    z.Borough AS pickup_borough,
    d.year,
    d.month,
    COUNT(*) AS antal_ture,
    ROUND(AVG(f.trip_distance), 2) AS gennemsnitlig_distance
FROM fact_trip AS f
JOIN dim_zone AS z
    ON f.pickup_zone_key = z.zone_key
JOIN dim_date AS d
    ON f.pickup_date_key = d.date_key
GROUP BY
    z.Borough,
    d.year,
    d.month
ORDER BY
    d.year,
    d.month,
    antal_ture DESC;


-- Analysequery 2:
-- antal ture og gennemsnitligt totalbeløb pr. dropoff-borough og måned

SELECT
    z.Borough AS dropoff_borough,
    d.year,
    d.month,
    COUNT(*) AS antal_ture,
    ROUND(AVG(f.total_amount), 2) AS gennemsnitligt_totalbeløb
FROM fact_trip AS f
JOIN dim_zone AS z
    ON f.dropoff_zone_key = z.zone_key
JOIN dim_date AS d
    ON f.dropoff_date_key = d.date_key
GROUP BY
    z.Borough,
    d.year,
    d.month
ORDER BY
    d.year,
    d.month,
    antal_ture DESC;