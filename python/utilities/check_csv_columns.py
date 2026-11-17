import csv
from pathlib import Path
import pyodbc

PROJECT_DIR = Path(__file__).resolve().parent
DATA_DIR = PROJECT_DIR / "data"

SERVER = r".\SQLEXPRESS"
DATABASE = "bakery_management"
DRIVER = "ODBC Driver 18 for SQL Server"

connection_string = (
    f"DRIVER={{{DRIVER}}};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

with pyodbc.connect(connection_string) as connection:
    cursor = connection.cursor()

    cursor.execute("""
        SELECT
            TABLE_NAME,
            COLUMN_NAME,
            COLUMNPROPERTY(
                OBJECT_ID(
                    QUOTENAME(TABLE_SCHEMA) + '.' +
                    QUOTENAME(TABLE_NAME)
                ),
                COLUMN_NAME,
                'IsIdentity'
            ) AS is_identity
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'dbo'
        ORDER BY TABLE_NAME, ORDINAL_POSITION;
    """)

    db_schema = {}
    for table, column, is_identity in cursor.fetchall():
        db_schema.setdefault(table.lower(), {})[column.lower()] = {
            "name": column,
            "identity": bool(is_identity),
        }

for csv_path in sorted(DATA_DIR.glob("*.csv")):
    table = csv_path.stem.lower()

    if table not in db_schema:
        print(f"\n[NO MATCHING TABLE] {csv_path.name}")
        continue

    with csv_path.open("r", encoding="utf-8-sig", newline="") as file:
        reader = csv.reader(file)
        headers = next(reader, [])

    csv_columns = {column.strip().lower() for column in headers}
    sql_columns = db_schema[table]

    missing = [
        info["name"]
        for name, info in sql_columns.items()
        if name not in csv_columns and not info["identity"]
    ]

    extra = [
        column for column in headers
        if column.strip().lower() not in sql_columns
    ]

    print(f"\n{csv_path.name}")

    if not missing and not extra:
        print("  Column names match.")
    else:
        if missing:
            print("  Missing from CSV:", ", ".join(missing))
        if extra:
            print("  Extra CSV columns:", ", ".join(extra))