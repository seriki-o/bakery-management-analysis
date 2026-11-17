from pathlib import Path
import sys
from collections import Counter
from datetime import date, datetime
from decimal import Decimal
import re

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

TABLE_FILES = {
    "roles": "roles.csv",
    "employees": "employees.csv",
    "ingredients": "ingredients.csv",
    "products": "products.csv",
    "suppliers": "suppliers.csv",
    "recipes": "recipes.csv",
    "orders": "orders.csv",
    "production_batches": "production_batches.csv",
    "purchases": "purchases.csv",
    "order_items": "order_items.csv",
    "payments": "payments.csv",
    "payment_adjustments": "payment_adjustments.csv",
    "purchase_items": "purchase_items.csv",
    "batch_ingredients": "batch_ingredients.csv",
    "inventory_movements": "inventory_movements.csv",
    "expenses": "expenses.csv",
    "audit_logs": "audit_logs.csv",
}


def quote_identifier(name):
    return "[" + name.replace("]", "]]" ) + "]"


def connect_to_database():
    connection_string = (
        f"DRIVER={{{DRIVER}}};SERVER={SERVER};DATABASE={DATABASE};"
        "Trusted_Connection=yes;TrustServerCertificate=yes;"
    )
    return pyodbc.connect(connection_string, autocommit=False)


def get_table_metadata(cursor, tables):
    cursor.execute("""
        SELECT t.name AS table_name, c.name AS column_name, c.is_identity,
               c.is_computed, c.is_nullable, dc.definition AS default_definition,
               c.column_id
        FROM sys.tables AS t
        JOIN sys.schemas AS s ON s.schema_id = t.schema_id
        JOIN sys.columns AS c ON c.object_id = t.object_id
        LEFT JOIN sys.default_constraints AS dc ON dc.object_id = c.default_object_id
        WHERE s.name = 'dbo'
        ORDER BY t.name, c.column_id;
    """)
    all_columns = {}
    for row in cursor.fetchall():
        all_columns.setdefault(row.table_name, []).append({
            "name": row.column_name, "identity": bool(row.is_identity),
            "computed": bool(row.is_computed), "nullable": bool(row.is_nullable),
            "has_default": row.default_definition is not None,
        })

    cursor.execute("""
        SELECT t.name AS table_name, i.name AS index_name, i.is_primary_key,
               c.name AS column_name, ic.key_ordinal
        FROM sys.tables AS t
        JOIN sys.schemas AS s ON s.schema_id = t.schema_id
        JOIN sys.indexes AS i ON i.object_id = t.object_id
        JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
        JOIN sys.columns AS c ON c.object_id = t.object_id AND c.column_id = ic.column_id
        WHERE s.name = 'dbo' AND i.is_unique = 1 AND i.is_hypothetical = 0
          AND ic.is_included_column = 0
        ORDER BY t.name, i.name, ic.key_ordinal;
    """)
    unique_keys = {}
    for row in cursor.fetchall():
        unique_keys.setdefault(row.table_name, {}).setdefault(
            row.index_name, {"primary": bool(row.is_primary_key), "columns": []}
        )["columns"].append((row.key_ordinal, row.column_name))

    cursor.execute("""
        SELECT child.name AS child_table, parent.name AS parent_table
        FROM sys.foreign_keys AS fk
        JOIN sys.tables AS child ON child.object_id = fk.parent_object_id
        JOIN sys.tables AS parent ON parent.object_id = fk.referenced_object_id
        JOIN sys.schemas AS cs ON cs.schema_id = child.schema_id
        JOIN sys.schemas AS ps ON ps.schema_id = parent.schema_id
        WHERE cs.name = 'dbo' AND ps.name = 'dbo' AND fk.is_disabled = 0;
    """)
    dependencies = [(r.child_table, r.parent_table) for r in cursor.fetchall()]

    metadata = {}
    for table in tables:
        if table not in all_columns:
            raise RuntimeError(f"Required SQL table dbo.{table} was not found.")
        metadata[table] = {
            "columns": all_columns[table],
            "unique_keys": [
                {"name": name, "primary": details["primary"],
                 "columns": [col for _, col in sorted(details["columns"])]}
                for name, details in unique_keys.get(table, {}).items()
            ],
        }
    return metadata, dependencies


def dependency_order(tables, dependencies):
    table_set = set(tables)
    parents = {t: set() for t in tables}
    for child, parent in dependencies:
        if child in table_set and parent in table_set and child != parent:
            parents[child].add(parent)
    ordered, remaining = [], set(tables)
    while remaining:
        ready = [t for t in tables if t in remaining and not (parents[t] & remaining)]
        if not ready:
            raise RuntimeError("Foreign-key dependency cycle detected: " + ", ".join(sorted(remaining)))
        ordered.extend(ready)
        remaining.difference_update(ready)
    return ordered


def read_csv_records(table, filename, sql_columns):
    path = DATA_DIR / filename
    if not path.exists():
        raise FileNotFoundError(f"CSV not found: {path}")
    df = pd.read_csv(path)
    csv_lookup = {str(c).casefold(): c for c in df.columns}
    sql_lookup = {c["name"].casefold(): c for c in sql_columns}
    for key, col in sql_lookup.items():
        if key not in csv_lookup and not (col["identity"] or col["computed"] or col["nullable"] or col["has_default"]):
            raise ValueError(f"{table}: required SQL column '{col['name']}' is missing from {filename}.")
    selected = [(csv_lookup[c["name"].casefold()], c) for c in sql_columns
                if c["name"].casefold() in csv_lookup and not c["computed"]]
    column_names = [c["name"] for _, c in selected]
    records = []
    for row in df[[csv_name for csv_name, _ in selected]].itertuples(index=False, name=None):
        values = []
        for value, (_, col) in zip(row, selected):
            if pd.isna(value):
                values.append(None)
            elif col["identity"]:
                number = float(value)
                if not number.is_integer():
                    raise ValueError(f"{table}.{col['name']} contains a non-integer ID.")
                values.append(int(number))
            else:
                values.append(value)
        records.append(dict(zip(column_names, values)))
    return column_names, records


def value_for_signature(value):
    """Normalize pandas/ODBC values for reliable in-memory row comparison."""
    if value is None:
        return ("NULL",)
    if isinstance(value, pd.Timestamp):
        value = value.to_pydatetime()
    if isinstance(value, datetime):
        return ("DATETIME", value.isoformat(timespec="microseconds"))
    if isinstance(value, date):
        return ("DATE", value.isoformat())
    # CSV timestamps are read as strings by pandas, while SQL Server returns
    # datetime objects. Parse ISO-like date/time strings so both sides compare
    # using the same signature representation.
    if isinstance(value, str) and re.match(r"^\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}", value.strip()):
        text = value.strip().replace("Z", "+00:00")
        try:
            parsed = datetime.fromisoformat(text)
            return ("DATETIME", parsed.isoformat(timespec="microseconds"))
        except ValueError:
            pass
    if isinstance(value, (Decimal, float, int)) and not isinstance(value, bool):
        try:
            return ("NUMBER", Decimal(str(value)).normalize().to_eng_string())
        except Exception:
            pass
    return (type(value).__name__, str(value))


def record_signature(record, columns):
    return tuple(value_for_signature(record.get(col)) for col in columns)


def load_existing_signatures(cursor, table, columns):
    if not columns:
        raise RuntimeError(f"{table}: no non-identity columns available for duplicate comparison.")
    select_sql = ", ".join(quote_identifier(c) for c in columns)
    cursor.execute(f"SELECT {select_sql} FROM [dbo].{quote_identifier(table)};")
    counts = Counter()
    for row in cursor.fetchall():
        record = dict(zip(columns, row))
        counts[record_signature(record, columns)] += 1
    return counts


def find_existing_by_unique_key(cursor, table, record, unique_keys):
    table_sql = f"[dbo].{quote_identifier(table)}"
    for key in unique_keys:
        cols = key["columns"]
        if not cols or any(c not in record or record[c] is None for c in cols):
            continue
        where_sql = " AND ".join(f"{quote_identifier(c)} = ?" for c in cols)
        cursor.execute(f"SELECT TOP (1) 1 FROM {table_sql} WHERE {where_sql};",
                       tuple(record[c] for c in cols))
        if cursor.fetchone() is not None:
            return key["name"]
    return None


def main():
    print(f"Target database: {DATABASE} on {SERVER}")
    print("Insert-only: existing rows are never updated or deleted.")
    confirmation = input(f"Type {DATABASE} to confirm and continue: ").strip()
    if confirmation != DATABASE:
        print("Confirmation did not match. No connection or changes made.")
        return

    connection = None
    try:
        connection = connect_to_database()
        cursor = connection.cursor()
        metadata, dependencies = get_table_metadata(cursor, TABLE_FILES)
        ordered_tables = dependency_order(list(TABLE_FILES), dependencies)
        print("Load order: " + " -> ".join(ordered_tables))
        results = {}

        for table in ordered_tables:
            table_info = metadata[table]
            sql_columns = table_info["columns"]
            column_names, records = read_csv_records(table, TABLE_FILES[table], sql_columns)
            if not records:
                results[table] = {"inserted": 0, "skipped": 0}
                print(f"{table}: CSV empty; skipped.")
                continue

            identity_columns = [c["name"] for c in sql_columns if c["identity"]]
            csv_names = {c.casefold() for c in column_names}
            csv_has_identity = any(c.casefold() in csv_names for c in identity_columns)
            insert_columns = ", ".join(quote_identifier(c) for c in column_names)
            placeholders = ", ".join("?" for _ in column_names)
            insert_sql = f"INSERT INTO [dbo].{quote_identifier(table)} ({insert_columns}) VALUES ({placeholders});"

            # Tables without a usable unique key (notably audit_logs and
            # batch_ingredients) use a full non-identity row signature.
            fallback_columns = [c["name"] for c in sql_columns
                                if not c["identity"] and not c["computed"] and c["name"] in column_names]
            usable_unique_keys = [
                key for key in table_info["unique_keys"]
                if key["columns"] and all(c in column_names for c in key["columns"])
            ]
            use_fallback = not usable_unique_keys
            existing_counts = load_existing_signatures(cursor, table, fallback_columns) if use_fallback else Counter()
            incoming_counts = Counter()
            inserted = skipped = 0
            identity_enabled = False
            try:
                if csv_has_identity:
                    cursor.execute(f"SET IDENTITY_INSERT [dbo].{quote_identifier(table)} ON;")
                    identity_enabled = True

                for record in records:
                    if use_fallback:
                        sig = record_signature(record, fallback_columns)
                        incoming_counts[sig] += 1
                        # Skip only the number of copies already present in DB.
                        # Extra identical copies in the CSV are preserved.
                        if incoming_counts[sig] <= existing_counts[sig]:
                            skipped += 1
                            continue
                    elif find_existing_by_unique_key(cursor, table, record, usable_unique_keys):
                        skipped += 1
                        continue
                    cursor.execute(insert_sql, tuple(record[c] for c in column_names))
                    inserted += 1

                if identity_enabled:
                    cursor.execute(f"SET IDENTITY_INSERT [dbo].{quote_identifier(table)} OFF;")
                    identity_enabled = False
                results[table] = {"inserted": inserted, "skipped": skipped}
                print(f"{table}: inserted {inserted:,}; skipped existing {skipped:,}.")
            finally:
                if identity_enabled:
                    cursor.execute(f"SET IDENTITY_INSERT [dbo].{quote_identifier(table)} OFF;")

        connection.commit()
        print("\nIncremental load completed successfully.")
        print(f"Total inserted: {sum(v['inserted'] for v in results.values()):,}")
        print(f"Total skipped: {sum(v['skipped'] for v in results.values()):,}")
    except Exception as error:
        if connection is not None:
            connection.rollback()
        print("\nINCREMENTAL LOAD FAILED — transaction rolled back.")
        print(f"Reason: {error}")
        sys.exit(1)
    finally:
        if connection is not None:
            connection.close()


if __name__ == "__main__":
    main()
