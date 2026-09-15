# Datamodel

**Version 1.2 · Elevskabelon**

## Indhold

1. [Første modelskitse](#1-første-modelskitse)
2. [Grain](#2-grain)
3. [Measures og dimensions](#3-measures-og-dimensions)
4. [Relationer og roller](#4-relationer-og-roller)
5. [Modeldiagram](#5-modeldiagram)
6. [Kontroller](#6-kontroller)
7. [Forklaring og kilder](#7-forklaring-og-kilder)

---

# 1. Første modelskitse

Vælg 2–3 analysebehov fra mandag. Skriv kort, hvilke oplysninger modellen skal gøre nemme at bruge.

> TODO
Modellen skal gøre det nemt at undersøge:

1. Hvilke pickup-zoner har flest ture?
2. Hvilke boroughs har flest ture, og hvad er den gennemsnitlige distance?
3. Hvordan varierer antal ture og gennemsnitlig distance over tid?

Modellen skal derfor indeholde taxiture, zoneoplysninger og datooplysninger.

Tegn en første modelskitse med almindelige ord, før du færdiggør den formelle model.

> TODO
Første skitse:

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


## 2. Grain

Erstat linjen og `TODO` med:

```markdown
> Én række i `fact_trip` repræsenterer én taxitur.

Dette grain passer til analysebehovene, fordi hver tur har en pickup-zone, en
dropoff-zone, en pickup-dato, en dropoff-dato og forskellige numeriske værdier.
Dermed kan turene tælles og grupperes efter zone og dato, og measures som
distance og beløb kan beregnes.

`trip_key` identificerer teknisk den enkelte række i `fact_trip`. Den beskriver
ikke turens faglige grain, men fungerer som en teknisk primærnøgle.

Formulér hvad én række i `fact_trip` repræsenterer.

> Én række i `fact_trip` repræsenterer TODO.

Forklar hvorfor dette grain passer til dine analysebehov.

> TODO

# 3. Measures og dimensions

**Vigtigste measures:**

- `passenger_count`: antal passagerer
- `trip_distance`: turens afstand i miles
- `fare_amount`: grundpris
- `total_amount`: samlet beløb


> TODO

**Vigtigste dimensions:**

- `dim_zone`: pickup- og dropoff-zone
- `dim_date`: pickup- og dropoff-dato


Forklar kort forskellen på en measure og en dimension i din model.

> TODO
En measure er en numerisk værdi, som kan tælles, summeres eller
gennemsnitsberegnes. En dimension beskriver den sammenhæng, som en measure
analyseres efter, for eksempel en zone eller en dato.

# 4. Relationer og roller

Forklar hvordan `dim_zone` bruges i pickup- og dropoff-rollen.

> TODO
`dim_zone` bruges i to roller. `pickup_zone_key` peger på den zone, hvor turen
starter, mens `dropoff_zone_key` peger på den zone, hvor turen slutter.
Det er den samme dimension, men relationerne har forskellige faglige roller.


Forklar hvordan `dim_date` bruges i pickup- og dropoff-rollen.

> TODO
`dim_date` bruges også i to roller. `pickup_date_key` peger på datoen, hvor
turen starter, mens `dropoff_date_key` peger på datoen, hvor turen slutter.
På den måde kan samme dato-dimension bruges til begge tidsmæssige roller.

# 5. Modeldiagram

Tegn dit eget diagram med tabeller, nøgler, relationer og roller.

Du kan bruge Mermaid, tekstdiagram eller et billede af en håndtegnet model. Vis selv de tabeller, nøgler og relationer, du har valgt. Markér hvilken rolle hver relation spiller, og forklar om en dimension kan bruges i flere roller.

> TODO: Indsæt dit eget diagram her.
                    +----------------------+
                    |       DIM_ZONE       |
                    +----------------------+
                    | PK zone_key          |
                    |    borough           |
                    |    zone              |
                    |    service_zone      |
                    +----------------------+
                       |              |
           pickup_zone |              | dropoff_zone
                     1 |              | 1
                       |              |
                     * |              | *
                 +--------------------------+
                 |        FACT_TRIP         |
                 +--------------------------+
                 | PK trip_key              |
                 | FK pickup_zone_key       |
                 | FK dropoff_zone_key      |
                 | FK pickup_date_key       |
                 | FK dropoff_date_key      |
                 |    trip_distance         |
                 |    fare_amount           |
                 |    total_amount          |
                 +--------------------------+
                     * |              | *
                       |              |
            pickup_date|              |dropoff_date
                     1 |              | 1
                       |              |
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

# 6. Kontroller

Beskriv hvilke kontroller du har lavet.

Du skal som minimum kunne vise:

- om dimensionsnøglerne er entydige;
- om `dim_date` dækker både pickup- og dropoff-datoer;
- om joins til pickup/dropoff-zone giver manglende matches;
- om join til dimensions ikke giver uventet flere fact-rækker.

> TODO
Jeg kontrollerer modellen på følgende måder:

- `dim_zone`: `COUNT(*)` sammenlignes med `COUNT(DISTINCT zone_key)`.
- `dim_date`: antal rækker sammenlignes med antal unikke `date_key`.
- `dim_date`: minimums- og maksimumsdato kontrolleres mod både pickup- og
  dropoff-datoerne i raw-data.
- Pickup-zone: fact-tabellen left-joines til `dim_zone`, og manglende matches
  tælles.
- Dropoff-zone: fact-tabellen left-joines til `dim_zone`, og manglende matches
  tælles.
- Pickup- og dropoff-dato: begge nøgler kontrolleres mod `dim_date`.
- Kardinalitet: antal rækker i `fact_trip` sammenlignes med antal rækker efter
  joins til dimensionerne. Antallet må ikke blive større, fordi hver
  dimensionsnøgle skal være entydig.

# 7. Forklaring og kilder

Begrund grain, valgte measures og dimensions ud fra analysebehovene. Forklar dimensionernes roller, og vis hvordan du kontrollerer modellens relationer.

Angiv de kilder, du har anvendt, fx dataordbog, DuckDB-dokumentation eller Kimball-begreber.

> TODO
Jeg har valgt én taxitur som grain, fordi mandagens analysebehov handler om
at tælle ture og beregne gennemsnit for distance og beløb. `fact_trip` gemmer
de numeriske measures og nøglerne til dimensionerne.

`dim_zone` gør det muligt at analysere ture efter borough, zone og servicezone.
Den bruges både som pickup-zone og dropoff-zone. `dim_date` gør det muligt at
analysere ture efter år, måned, dag og ugedag. Den bruges både for turens
startdato og slutdato.

Jeg bruger surrogate-lignende tekniske nøgler i fact-tabellen:
`trip_key` identificerer en fact-række, mens zone- og datonøglerne fungerer
som foreign keys til dimensionerne. Raw-filerne bevares uændret, og de
modellerede tabeller bygges ud fra raw-dataene.

Jeg har brugt følgende kilder:

- NYC TLC Yellow Taxi Data Dictionary:
  https://www.nyc.gov/assets/tlc/downloads/pdf/data_dictionary_trip_records_yellow.pdf
- DuckDB dokumentation om Parquet, CSV, joins og tabeller:
  https://duckdb.org/docs/current/
- Kimball Group om grain og dimensionel modellering:
  https://www.kimballgroup.com/data-warehouse-business-intelligence-resources/kimball-techniques/
