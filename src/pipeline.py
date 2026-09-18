"""Dag04: reproducerbar batch-pipeline til NYC Taxi-projektet.

Pipeline-rækkefølge:
    02_dimensions.sql -> 03_fact_trip.sql -> 04_aggregates.sql

01_explore.sql er udforskende arbejde og indgår derfor ikke i rebuilden.
"""
from pathlib import Path

import duckdb


DB_PATH = Path("data/warehouse/taxi_20556.duckdb")

# 01_explore.sql er udforskning og er bevidst ikke et rebuild-trin.
STEPS = (
    ("dimensions", Path("sql/02_dimensions.sql")),
    ("fact", Path("sql/03_fact_trip.sql")),
    ("aggregate", Path("sql/04_aggregates.sql")),
)

MAX_RESULT_ROWS = 10


def load_statements(
    connection: duckdb.DuckDBPyConnection, sql_path: Path
) -> list[str]:
    """Læs og parse en påkrævet SQL-fil eller stop med en tydelig fejl."""
    if not sql_path.is_file():
        raise FileNotFoundError(f"Påkrævet SQL-fil mangler: {sql_path}")

    sql = sql_path.read_text(encoding="utf-8")

    # DuckDB-parseren håndterer bl.a. kommentarer og semikolon korrekt.
    parsed = connection.extract_statements(sql)
    statements = [item.query.strip() for item in parsed if item.query.strip()]

    if not statements:
        raise ValueError(f"SQL-filen indeholder ingen kørbare statements: {sql_path}")

    return statements


def _is_select_statement(
    connection: duckdb.DuckDBPyConnection, statement: str
) -> bool:
    """Returnér True, hvis DuckDB-parseren klassificerer statementet som SELECT."""
    parsed = connection.extract_statements(statement)
    return bool(parsed) and parsed[0].type == duckdb.StatementType.SELECT


def _print_select_result(result: duckdb.DuckDBPyConnection) -> None:
    """Vis et kort preview af et SELECT-resultat i terminalen."""
    if not result.description:
        print("    (intet resultat)")
        return

    columns = [column[0] for column in result.description]
    rows = result.fetchmany(MAX_RESULT_ROWS + 1)
    shown_rows = rows[:MAX_RESULT_ROWS]

    print("    " + " | ".join(columns))
    print("    " + "-+-".join("-" * len(column) for column in columns))

    if not shown_rows:
        print("    (0 rækker)")
        return

    for row in shown_rows:
        print("    " + " | ".join("NULL" if value is None else str(value) for value in row))

    if len(rows) > MAX_RESULT_ROWS:
        print(f"    ... viser kun de første {MAX_RESULT_ROWS} rækker")


def run_step(
    connection: duckdb.DuckDBPyConnection,
    step_name: str,
    statements: list[str],
) -> None:
    """Kør ét trin og gør det synligt, hvor en eventuel fejl opstår."""
    print(f"\n=== Trin: {step_name} ({len(statements)} statements) ===")

    for index, statement in enumerate(statements, start=1):
        first_line = statement.splitlines()[0].strip()
        if len(first_line) > 100:
            first_line = first_line[:97] + "..."

        print(f"[{index}/{len(statements)}] {first_line}")

        try:
            is_select = _is_select_statement(connection, statement)
            result = connection.execute(statement)
        except Exception as exc:
            print(f"[FEJL] Trin '{step_name}', statement {index} fejlede.")
            print(f"       {exc}")
            raise

        if is_select:
            _print_select_result(result)
        else:
            print("    OK")

    print(f"=== Trin '{step_name}' færdigt ===")


def main() -> None:
    """Kør hele builden sikkert i den rækkefølge, afhængighederne kræver."""
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    connection = duckdb.connect(str(DB_PATH))
    transaction_started = False

    try:
        # Valider ALLE SQL-filer før databasen ændres.
        print("Validerer påkrævede SQL-filer...")
        loaded_steps: list[tuple[str, Path, list[str]]] = []

        for step_name, sql_path in STEPS:
            statements = load_statements(connection, sql_path)
            loaded_steps.append((step_name, sql_path, statements))
            print(f"  OK: {sql_path} ({len(statements)} statements)")

        print(f"\nDatabase: {DB_PATH}")
        print("Starter én samlet transaktion...")
        connection.execute("BEGIN TRANSACTION")
        transaction_started = True

        for step_name, sql_path, statements in loaded_steps:
            print(f"\nFil: {sql_path}")
            run_step(connection, step_name, statements)

        connection.execute("COMMIT")
        transaction_started = False

        print("\n[SUCCESS] Pipeline gennemført.")
        print("Alle dimensions-, fact- og aggregate-ændringer er committed samlet.")

    except Exception as exc:
        if transaction_started:
            try:
                connection.execute("ROLLBACK")
                print("\n[ROLLBACK] Alle ændringer fra denne pipeline-kørsel er rullet tilbage.")
            except Exception as rollback_exc:
                print(f"\n[ADVARSEL] Rollback fejlede også: {rollback_exc}")

        print(f"[FEJL] Pipeline stoppet: {exc}")
        raise

    finally:
        connection.close()
        print("DuckDB-forbindelsen er lukket.")


if __name__ == "__main__":
    main()
