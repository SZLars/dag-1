-- 20556 · Dag03 · Aggregate
-- Forudsætning:
-- sql/02_dimensions.sql og sql/03_fact_trip.sql er kørt først.
--
-- Grain:
-- én række pr. pickup-dato og pickup-zone

CREATE OR REPLACE TABLE aggregate_trip_day_zone AS
SELECT
    pickup_date_key,
    pickup_zone_key,
    COUNT(*) AS trip_count,
    SUM(trip_distance) AS distance_sum,
    COUNT(trip_distance) AS distance_count
FROM fact_trip
GROUP BY
    pickup_date_key,
    pickup_zone_key;


-- Kontrol: hvert aggregate-grain forekommer højst én gang

SELECT
    COUNT(*) AS duplicate_groups
FROM (
    SELECT
        pickup_date_key,
        pickup_zone_key
    FROM aggregate_trip_day_zone
    GROUP BY
        pickup_date_key,
        pickup_zone_key
    HAVING COUNT(*) > 1
) AS duplicates;


-- Kontrol: antal ture og afstandsgrundlag stemmer med fact

SELECT
    (SELECT COUNT(*) FROM fact_trip) AS fact_trip_count,
    (SELECT SUM(trip_count) FROM aggregate_trip_day_zone)
        AS aggregate_trip_count,
    (SELECT COUNT(trip_distance) FROM fact_trip)
        AS fact_distance_count,
    (SELECT SUM(distance_count) FROM aggregate_trip_day_zone)
        AS aggregate_distance_count,
    ROUND(
        (SELECT SUM(trip_distance) FROM fact_trip),
        2
    ) AS fact_distance_sum,
    ROUND(
        (SELECT SUM(distance_sum) FROM aggregate_trip_day_zone),
        2
    ) AS aggregate_distance_sum;


-- Kontrol: NULL og nul undersøges separat

SELECT
    COUNT(*) AS fact_rows,
    COUNT(trip_distance) AS rows_with_distance,
    COUNT(*) - COUNT(trip_distance) AS rows_with_null_distance,
    COUNT(*) FILTER (WHERE trip_distance = 0)
        AS rows_with_zero_distance
FROM fact_trip;


-- Kontrol: aggregate-resultatet kan genkøres uden fordobling

SELECT
    COUNT(*) AS aggregate_rows,
    COUNT(*) AS rows_after_rerun_check
FROM aggregate_trip_day_zone;


-- Analysequery 1:
-- antal ture og gennemsnitlig distance pr. borough og måned

SELECT
    d.year,
    d.month,
    COALESCE(z.Borough, 'Ukendt') AS pickup_borough,
    SUM(a.trip_count) AS antal_ture,
    ROUND(
        SUM(a.distance_sum) / NULLIF(SUM(a.distance_count), 0),
        2
    ) AS gennemsnitlig_distance
FROM aggregate_trip_day_zone AS a
LEFT JOIN dim_date AS d
    ON a.pickup_date_key = d.date_key
LEFT JOIN dim_zone AS z
    ON a.pickup_zone_key = z.zone_key
GROUP BY
    d.year,
    d.month,
    z.Borough
ORDER BY
    d.year,
    d.month,
    antal_ture DESC;


-- Analysequery 2:
-- antal ture og gennemsnitlig distance pr. pickup-zone og måned

SELECT
    d.year,
    d.month,
    COALESCE(z.Zone, 'Ukendt') AS pickup_zone,
    SUM(a.trip_count) AS antal_ture,
    ROUND(
        SUM(a.distance_sum) / NULLIF(SUM(a.distance_count), 0),
        2
    ) AS gennemsnitlig_distance
FROM aggregate_trip_day_zone AS a
LEFT JOIN dim_date AS d
    ON a.pickup_date_key = d.date_key
LEFT JOIN dim_zone AS z
    ON a.pickup_zone_key = z.zone_key
GROUP BY
    d.year,
    d.month,
    z.Zone
ORDER BY
    d.year,
    d.month,
    antal_ture DESC
LIMIT 20;


-- Kontrol: sammenlign grovere aggregate med fact

WITH aggregate_summary AS (
    SELECT
        d.year,
        d.month,
        z.Borough AS pickup_borough,
        SUM(a.trip_count) AS aggregate_trip_count,
        SUM(a.distance_sum) AS aggregate_distance_sum,
        SUM(a.distance_count) AS aggregate_distance_count
    FROM aggregate_trip_day_zone AS a
    LEFT JOIN dim_date AS d
        ON a.pickup_date_key = d.date_key
    LEFT JOIN dim_zone AS z
        ON a.pickup_zone_key = z.zone_key
    GROUP BY
        d.year,
        d.month,
        z.Borough
),
fact_summary AS (
    SELECT
        d.year,
        d.month,
        z.Borough AS pickup_borough,
        COUNT(*) AS fact_trip_count,
        SUM(f.trip_distance) AS fact_distance_sum,
        COUNT(f.trip_distance) AS fact_distance_count
    FROM fact_trip AS f
    LEFT JOIN dim_date AS d
        ON f.pickup_date_key = d.date_key
    LEFT JOIN dim_zone AS z
        ON f.pickup_zone_key = z.zone_key
    GROUP BY
        d.year,
        d.month,
        z.Borough
)
SELECT
    COALESCE(a.year, f.year) AS year,
    COALESCE(a.month, f.month) AS month,
    COALESCE(a.pickup_borough, f.pickup_borough) AS pickup_borough,
    a.aggregate_trip_count,
    f.fact_trip_count,
    a.aggregate_distance_count,
    f.fact_distance_count,
    ROUND(a.aggregate_distance_sum, 2) AS aggregate_distance_sum,
    ROUND(f.fact_distance_sum, 2) AS fact_distance_sum
FROM aggregate_summary AS a
FULL OUTER JOIN fact_summary AS f
    ON a.year IS NOT DISTINCT FROM f.year
    AND a.month IS NOT DISTINCT FROM f.month
    AND a.pickup_borough IS NOT DISTINCT FROM f.pickup_borough
ORDER BY
    year,
    month,
    pickup_borough;