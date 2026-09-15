# Arkitektur

**Version 1.0**

## Indhold

1. [Data](#data)
2. [Analysebehov](#analysebehov)
3. [Arkitekturskitse](#arkitekturskitse)

## Data

**Yellow Taxi:** Én rå række repræsenterer én afsluttet taxitur. Rækken indeholder blandt andet tidspunkt, pickup- og dropoff-zone, distance, betaling og passageroplysninger.

**Taxi Zone Lookup:** Én række repræsenterer én geografisk taxi-zone. `LocationID` bruges til at koble zonen sammen med `PULocationID` eller `DOLocationID` i tripdataene.

### Relevante felter

- `tpep_pickup_datetime`: Tidspunktet hvor turen blev startet.
- `tpep_dropoff_datetime`: Tidspunktet hvor turen blev afsluttet.
- `PULocationID`: ID for pickup-zonen.
- `DOLocationID`: ID for dropoff-zonen.
- `trip_distance`: Turens afstand i miles.
- `fare_amount`: Grundprisen for turen før eventuelle ekstra beløb.

Feltbetydningerne er undersøgt i [NYC TLC Yellow Taxi Data Dictionary](https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf).

Zone Lookup indeholder blandt andet:

- `LocationID`: Zone-ID, som bruges som nøgle i joinet.
- `Borough`: Området eller bydelen zonen tilhører.
- `Zone`: Navnet på taxi-zonen.
- `service_zone`: Den servicezone som området tilhører.

En vigtig observation er, at nogle ture kan have en `PULocationID`, som ikke kan matches til en række i Zone Lookup. Disse ture skal ikke slettes fra raw-data. Et `LEFT JOIN` bevarer turene, mens zonefelterne bliver `NULL`, hvis der ikke findes et match.

## Analysebehov

1. Hvilke pickup-zoner har flest taxiture?
2. Hvilke boroughs har flest taxiture, og hvad er den gennemsnitlige distance i de enkelte boroughs?
3. Hvordan varierer antallet af ture og den gennemsnitlige distance over tid?

Det andet analysebehov bruger Zone Lookup, fordi `PULocationID` kobles til `LocationID`, `Borough` og `Zone`.

## Arkitekturskitse

```mermaid
flowchart LR
    A[Yellow Taxi Parquet] --> B[Raw data]
    C[Taxi Zone Lookup CSV] --> B
    B --> D[DuckDB SQL]
    D --> E[Dataundersøgelse]
    D --> F[Join på PULocationID = LocationID]
    F --> G[Afledte analyse-resultater]
    G --> H[Terminal eller rapport]

    D -. senere .-> I[Modeled tables]
    I -. senere .-> J[Aggregates]