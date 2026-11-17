
from pathlib import Path
import sys

import pandas as pd
import pyodbc


# ============================================================
# CONFIGURATION
# ============================================================

PROJECT_DIR = Path(__file__).resolve().parents[2]
DATA_DIR = PROJECT_DIR / "data"

SERVER = r".\SQLEXPRESS"
DATABASE = "bakery_management"
DRIVER = "ODBC Driver 18 for SQL Server"

# Only these CSVs are permitted to load into SQL Server.
TABLE_FILES = {
    "roles": "roles.csv",
    "products": "products.csv",
    "ingredients": "ingredients.csv",
    "suppliers": "suppliers.csv",
    "employees": "employees.csv",
    "purchases": "purchases.csv",
    "orders": "orders.csv",
    "production_batches": "production_batches.csv",
    "recipes": "recipes.csv",
    "expenses": "expenses.csv",
    "purchase_items": "purchase_items.csv",
    "order_items": "order_items.csv",
    "payments": "payments.csv",
    "batch_ingredients": "batch_ingredients.csv",
    "inventory_movements": "inventory_movements.csv",
    "payment_adjustments": "payment_adjustments.csv",
    "audit_logs": "audit_logs.csv",
}


# ============================================================
# DATABASE CONNECTION
# ============================================================

def connect_to_database():
    connection_string = (
        f"DRIVER={{{DRIVER}}};"
        f"SERVER={SERVER};"
        f"DATABASE={DATABASE};"
        "Trusted_Connection=yes;"
        "TrustServerCertificate=yes;"
    )

    return pyodbc.connect(connection_string, autocommit=False)


# ============================================================
# DATABASE METADATA
# ============================================================

def get_table_metadata(cursor):
    """
    Read actual SQL Server columns, identity columns,
    defaults, nullability, and foreign-key relationships.
    """

    cursor.execute("""
        SELECT
            s.name AS schema_name,
            t.name AS table_name,
            c.name AS column_name,
            c.is_nullable,
            c.is_identity,
            c.is_computed,
            dc.definition AS default_definition,
            c.column_id
        FROM sys.tables AS t
        JOIN sys.schemas AS s
            ON s.schema_id = t.schema_id
        JOIN sys.columns AS c
            ON c.object_id = t.object_id
        LEFT JOIN sys.default_constraints AS dc
            ON dc.object_id = c.default_object_id
        WHERE t.is_ms_shipped = 0
        ORDER BY s.name, t.name, c.column_id;
    """)

    columns = {}

    for row in cursor.fetchall():
        schema = row.schema_name
        table = row.table_name

        columns.setdefault((schema, table), []).append({
            "name": row.column_name,
            "nullable": bool(row.is_nullable),
            "identity": bool(row.is_identity),
            "computed": bool(row.is_computed),
            "has_default": row.default_definition is not None,
        })

    cursor.execute("""
        SELECT
            OBJECT_SCHEMA_NAME(fk.parent_object_id) AS child_schema,
            OBJECT_NAME(fk.parent_object_id) AS child_table,
            OBJECT_SCHEMA_NAME(fk.referenced_object_id) AS parent_schema,
            OBJECT_NAME(fk.referenced_object_id) AS parent_table
        FROM sys.foreign_keys AS fk;
    """)

    foreign_keys = [
        (
            row.child_schema,
            row.child_table,
            row.parent_schema,
            row.parent_table,
        )
        for row in cursor.fetchall()
    ]

    return columns, foreign_keys


def get_load_order(tables, foreign_keys, schema_name="dbo"):
    """
    Put referenced parent tables before dependent child tables.
    """

    dependencies = {table: set() for table in tables}

    for child_schema, child, parent_schema, parent in foreign_keys:
        if child_schema != schema_name or parent_schema != schema_name:
            continue

        if child in tables and parent in tables and child != parent:
            dependencies[child].add(parent)

    ordered = []
    remaining = set(tables)

    while remaining:
        ready = sorted(
            table for table in remaining
            if dependencies[table].isdisjoint(remaining)
        )

        if not ready:
            raise RuntimeError(
                "Could not determine a safe load order. "
                "There may be circular foreign-key dependencies: "
                + ", ".join(sorted(remaining))
            )

        ordered.extend(ready)
        remaining.difference_update(ready)

    return ordered


# ============================================================
# CSV PREPARATION
# ============================================================

def read_csv_for_table(table, filename, sql_columns):
    path = DATA_DIR / filename

    if not path.exists():
        raise FileNotFoundError(f"CSV not found: {path}")

    df = pd.read_csv(path)

    # Match CSV headers to SQL column names without case sensitivity.
    csv_lookup = {str(col).casefold(): col for col in df.columns}
    sql_lookup = {col["name"].casefold(): col for col in sql_columns}

    # Check required SQL columns before importing.
    for key, col in sql_lookup.items():
        if key not in csv_lookup:
            if (
                col["identity"]
                or col["computed"]
                or col["nullable"]
                or col["has_default"]
            ):
                continue

            raise ValueError(
                f"{table}: required SQL column '{col['name']}' "
                f"is missing from {filename}."
            )

    # Select only columns that exist in both SQL and the CSV.
    # This deliberately ignores extra CSV fields.
    selected_columns = []

    for col in sql_columns:
        csv_name = csv_lookup.get(col["name"].casefold())

        if csv_name is not None and not col["computed"]:
            selected_columns.append((csv_name, col))

    if df.empty:
        return [], []

    sql_names = [col["name"] for _, col in selected_columns]
    csv_names = [csv_name for csv_name, _ in selected_columns]

    # Pandas NaN/NaT values must become Python None for SQL NULL.
    records = []

    for row in df[csv_names].itertuples(index=False, name=None):
        values = []

        for value, (_, col) in zip(row, selected_columns):
            if pd.isna(value):
                values.append(None)
            elif col["identity"]:
                # IDs must be whole numbers.
                number = float(value)
                if not number.is_integer():
                    raise ValueError(
                        f"{table}.{col['name']} contains a non-integer ID."
                    )
                values.append(int(number))
            else:
                values.append(value)

        records.append(tuple(values))

    return sql_names, records


# ============================================================
# IMPORT
# ============================================================

def main():
    connection = None

    try:
        connection = connect_to_database()
        cursor = connection.cursor()

        print(f"Connected to {DATABASE} on {SERVER}.")

        metadata, foreign_keys = get_table_metadata(cursor)

        # Validate table presence and use dbo for this project.
        for table in TABLE_FILES:
            if ("dbo", table) not in metadata:
                raise RuntimeError(
                    f"SQL table dbo.{table} was not found. "
                    "No data has been imported."
                )

        # Confirm the real database supports the production CSV.
        production_columns = {
            col["name"].casefold()
            for col in metadata[("dbo", "production_batches")]
        }

        if "production_type" not in production_columns:
            raise RuntimeError(
                "The actual SQL table dbo.production_batches does not "
                "contain production_type. Apply the schema migration "
                "before importing. No data has been imported."
            )

        # This initial loader is intentionally insert-only.
        # Do not append duplicate rows or overwrite existing data.
        for table in TABLE_FILES:
            cursor.execute(f"""
                SELECT COUNT_BIG(*)
                FROM [dbo].[{table}];
            """)

            count = cursor.fetchone()[0]

            if count > 0:
                raise RuntimeError(
                    f"dbo.{table} already contains {count:,} rows. "
                    "This loader will not append duplicates or overwrite "
                    "existing records. No data has been imported."
                )

        load_order = get_load_order(
            list(TABLE_FILES.keys()),
            foreign_keys,
        )

        print("\nLoad order:")
        for number, table in enumerate(load_order, start=1):
            print(f"{number:2}. {table}")

        print("\nStarting import...")

        imported_counts = {}

        for table in load_order:
            filename = TABLE_FILES[table]
            sql_columns = metadata[("dbo", table)]

            column_names, records = read_csv_for_table(
                table,
                filename,
                sql_columns,
            )

            if not records:
                print(f"{table}: CSV is empty; skipped.")
                imported_counts[table] = 0
                continue

            # Enable identity insert only when the CSV provides an
            # identity column with values.
            identity_columns = [
                col["name"]
                for col in sql_columns
                if col["identity"]
            ]

            csv_has_identity = any(
                name.casefold() in {c.casefold() for c in column_names}
                for name in identity_columns
            )

            quoted_columns = ", ".join(
                f"[{name}]" for name in column_names
            )

            placeholders = ", ".join("?" for _ in column_names)

            insert_sql = (
                f"INSERT INTO [dbo].[{table}] ({quoted_columns}) "
                f"VALUES ({placeholders})"
            )

            try:
                if csv_has_identity:
                    cursor.execute(
                        f"SET IDENTITY_INSERT [dbo].[{table}] ON;"
                    )

                cursor.fast_executemany = True
                cursor.executemany(insert_sql, records)

                if csv_has_identity:
                    cursor.execute(
                        f"SET IDENTITY_INSERT [dbo].[{table}] OFF;"
                    )

                connection.commit()
                imported_counts[table] = len(records)

                print(f"{table}: imported {len(records):,} rows.")

            except Exception:
                connection.rollback()

                # Ensure identity insert is not left enabled.
                if csv_has_identity:
                    try:
                        cursor.execute(
                            f"SET IDENTITY_INSERT [dbo].[{table}] OFF;"
                        )
                        connection.commit()
                    except Exception:
                        connection.rollback()

                raise

        print("\nImport completed successfully.")
        print("\nSummary:")

        for table in load_order:
            print(f"{table}: {imported_counts.get(table, 0):,} rows")

        print(
            f"\nTotal rows imported: {sum(imported_counts.values()):,}"
        )

    except Exception as error:
        if connection is not None:
            connection.rollback()

        print("\nIMPORT STOPPED")
        print(f"Reason: {error}")
        print("Review the error before trying again.")
        sys.exit(1)

    finally:
        if connection is not None:
            connection.close()


if __name__ == "__main__":
    main()
