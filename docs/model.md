# Datamodel

**Version 1.2**

## Indhold

1. [Første modelskitse](#1-første-modelskitse)
2. [Grain](#2-grain)
3. [Measures og dimensions](#3-measures-og-dimensions)
4. [Relationer og roller](#4-relationer-og-roller)
5. [Modeldiagram](#5-modeldiagram)
6. [Kontroller](#6-kontroller)
7. [Forklaring og kilder](#7-forklaring-og-kilder)

# 1. Første modelskitse

Modellen skal gøre det nemt at undersøge:

1. Hvilke pickup-zoner har flest ture?
2. Hvilke boroughs har flest ture, og hvad er den gennemsnitlige distance?
3. Hvordan varierer antallet af ture og den gennemsnitlige distance over tid?

Modellen skal derfor indeholde taxiture, zoneoplysninger og datooplysninger.

Første modelskitse:

```text
Taxiture
├── pickup-zone
├── dropoff-zone
├── pickup-dato
├── dropoff-dato
├── distance
├── fare
└── total amount

Zoneoplysninger bruges til pickup- og dropoff-zoner.
Datooplysninger bruges til pickup- og dropoff-datoer.
```

# 2. Grain

Én række i `fact_trip` repræsenterer én taxitur.

Dette grain passer til analysebehovene, fordi hver tur har en pickup-zone,
en dropoff-zone, en pickup-dato, en dropoff-dato og numeriske værdier.
Dermed kan turene tælles og grupperes efter zone og dato, og measures som
distance og beløb kan beregnes.

`trip_key` identificerer teknisk den enkelte række i `fact_trip`. Den
beskriver ikke turens faglige grain, men fungerer som en teknisk primærnøgle.

# 3. Measures og dimensions

## Measures

- `passenger_count`: antal passagerer
- `trip_distance`: turens afstand i miles
- `fare_amount`: grundpris
- `total_amount`: samlet beløb

## Dimensions

- `dim_zone`: pickup- og dropoff-zone
- `dim_date`: pickup- og dropoff-dato

En measure er en numerisk værdi, som kan tælles, summeres eller
gennemsnitsberegnes. En dimension beskriver den sammenhæng, som en measure
analyseres efter, for eksempel en zone eller en dato.

# 4. Relationer og roller

`dim_zone` bruges i to roller. `pickup_zone_key` peger på den zone, hvor
turen starter, mens `dropoff_zone_key` peger på den zone, hvor turen slutter.
Det er den samme dimension, men relationerne har forskellige faglige roller.

`dim_date` bruges også i to roller. `pickup_date_key` peger på datoen, hvor
turen starter, mens `dropoff_date_key` peger på datoen, hvor turen slutter.
På den måde kan den samme dato-dimension bruges til begge tidsmæssige roller.

# 5. Modeldiagram

Diagrammet viser et star schema. `FACT_TRIP` er fact-tabellen, og
`DIM_ZONE` og `DIM_DATE` er dimensionstabeller. Hver dimension bruges i to
forskellige roller.

```text
+----------------------+
|       DIM_ZONE       |
+----------------------+
| PK zone_key          |
|    borough           |
|    zone              |
|    service_zone      |
+----------------------+
       |          |
 pickup|          |dropoff
     1 |          | 1
       |          |
     * |          | *
+--------------------------+
|        FACT_TRIP         |
+--------------------------+
| PK trip_key              |
| FK pickup_zone_key       |
| FK dropoff_zone_key      |
| FK pickup_date_key       |
| FK dropoff_date_key      |
|    passenger_count       |
|    trip_distance         |
|    fare_amount           |
|    total_amount          |
+--------------------------+
     * |          | *
       |          |
 pickup|          |dropoff
 date  |          | date
     1 |          | 1
       |          |
+----------------------+
|       DIM_DATE       |
+----------------------+
| PK date_key          |
|    date_day          |
|    year              |
|    month             |
|    day               |
|    weekday           |
+----------------------+
```

`dim_zone` og `dim_date` er role-playing dimensions, fordi den samme
dimension bruges flere gange med forskellige roller.

# 6. Kontroller

Jeg har lavet følgende kontroller:

- `dim_zone`: antal rækker sammenlignes med antal unikke `zone_key`.
- `dim_date`: antal rækker sammenlignes med antal unikke `date_key`.
- `dim_date`: datoerne kontrolleres mod både pickup- og dropoff-datoer.
- Pickup-zone: manglende matches til `dim_zone` tælles.
- Dropoff-zone: manglende matches til `dim_zone` tælles.
- Pickup-dato: manglende matches til `dim_date` tælles.
- Dropoff-dato: manglende matches til `dim_date` tælles.
- Antal rækker i `fact_trip` sammenlignes med antal rækker efter joins til
  dimensionerne.

Kontrollerne viste:

- `dim_zone` har 265 rækker og 265 unikke nøgler.
- `fact_trip` har 3.475.226 rækker.
- Antallet af raw-rækker og fact-rækker er det samme.
- Der mangler ingen pickup-zone-matches.
- Der mangler ingen dropoff-zone-matches.
- Der mangler ingen pickup-date-matches.
- Der er ét manglende dropoff-date-match.

Det ene manglende dropoff-date-match skyldes en rå taxitur, hvor
`tpep_dropoff_datetime` mangler. Rækken bevares i `fact_trip`, men dens
`dropoff_date_key` bliver `NULL`. Raw-data ændres ikke.

Kardinalitetskontrollen viste, at joins til dimensionerne ikke skabte ekstra
fact-rækker. Begge antal var 3.475.226.

# 7. Forklaring og kilder

Jeg har valgt én taxitur som grain, fordi analysebehovene handler om at
tælle ture og beregne gennemsnit for distance og beløb. `fact_trip` gemmer
de numeriske measures og nøglerne til dimensionerne.

`dim_zone` gør det muligt at analysere ture efter borough, zone og
servicezone. Den bruges både som pickup-zone og dropoff-zone.

`dim_date` gør det muligt at analysere ture efter år, måned, dag og ugedag.
Den bruges både for turens startdato og slutdato.

`trip_key` identificerer teknisk en fact-række. Zone- og datonøglerne fungerer
som foreign keys til dimensionerne. Raw-filerne bevares uændret, og de
modellerede tabeller bygges ud fra raw-dataene.

Jeg har brugt følgende kilder:

- [NYC TLC Trip Record Data](https://www.nyc.gov/site/tlc/about/tlc-trip-record-data.page)
- [Yellow Taxi Data Dictionary](https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf)
- [DuckDB documentation](https://duckdb.org/docs/current/)
- [Kimball Group: Grain](https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/dimensional-modeling-techniques/grain/)