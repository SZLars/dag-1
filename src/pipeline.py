"""Torsdagsopgave: implementér en reproducerbar batch-pipeline.

Mandag til onsdag køres SQL-filerne enkeltvis med run_sql_file.py.
Denne fil skal først kunne køre, når du implementerer torsdagens opgave.
"""
from pathlib import Path

DB_PATH = Path("data/warehouse/taxi_20556.duckdb")


def main() -> None:
    """Byg den analytiske løsning i den rækkefølge, afhængighederne kræver."""
    # TODO: Implementér torsdagens pipeline.
    #
    # Krav:
    # - Kør dimensions-, fact- og aggregate-trinnene i en begrundet rækkefølge.
    # - Stop tydeligt, hvis en påkrævet SQL-fil mangler eller ikke indeholder SQL.
    # - Brug den lokale DuckDB-database på DB_PATH.
    # - Luk databaseforbindelsen, også hvis et trin fejler.
    # - Vis hvilket trin der kører, så en fejl kan placeres.
    # - En ny kørsel må ikke fordoble de afledte data.
    #
    # Dokumentér kort de Python- og DuckDB-kilder, du bruger.
    raise NotImplementedError(
        "Pipelineopgaven implementeres torsdag. "
        "Indtil da køres SQL-filerne enkeltvis med src/run_sql_file.py."
    )


if __name__ == "__main__":
    main()
