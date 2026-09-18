-- 20556 · Tirsdag · Dimensioner

CREATE OR REPLACE TABLE dim_zone AS
SELECT
    CAST(LocationID AS INTEGER) AS zone_key,
    Borough,
    Zone,
    service_zone
FROM read_csv_auto('data/raw/taxi_zone_lookup.csv');

SELECT
    COUNT(*) AS antal_zoner,
    COUNT(DISTINCT zone_key) AS unikke_zone_nogler
FROM dim_zone;


CREATE OR REPLACE TABLE dim_date AS
WITH all_dates AS (
    SELECT CAST(tpep_pickup_datetime AS DATE) AS date_day
    FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')

    UNION ALL

    SELECT CAST(tpep_dropoff_datetime AS DATE) AS date_day
    FROM read_parquet('data/raw/yellow_tripdata_2025-01.parquet')
),
date_range AS (
    SELECT
        MIN(date_day) AS min_date,
        MAX(date_day) AS max_date
    FROM all_dates
),
dates AS (
    SELECT unnest(
        generate_series(min_date, max_date, INTERVAL 1 DAY)
    ) AS date_day
    FROM date_range
)
SELECT
    CAST(strftime(date_day, '%Y%m%d') AS INTEGER) AS date_key,
    date_day,
    year(date_day) AS year,
    month(date_day) AS month,
    day(date_day) AS day,
    dayname(date_day) AS weekday
FROM dates;

SELECT
    COUNT(*) AS antal_datoer,
    COUNT(DISTINCT date_key) AS unikke_dato_nogler,
    MIN(date_day) AS foerste_dato,
    MAX(date_day) AS sidste_dato
FROM dim_date;