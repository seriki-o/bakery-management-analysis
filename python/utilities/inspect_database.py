
import pyodbc

server = r".\SQLEXPRESS"
database = "bakery_management"
driver = "ODBC Driver 18 for SQL Server"

connection_string = (
    f"DRIVER={{{driver}}};"
    f"SERVER={server};"
    f"DATABASE={database};"
    "Trusted_Connection=yes;"
    "TrustServerCertificate=yes;"
)

with pyodbc.connect(connection_string) as connection:
    cursor = connection.cursor()

    cursor.execute("""
        SELECT
            TABLE_SCHEMA,
            TABLE_NAME,
            COLUMN_NAME,
            DATA_TYPE,
            ORDINAL_POSITION,
            IS_NULLABLE
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = 'dbo'
        ORDER BY TABLE_NAME, ORDINAL_POSITION;
    """)

    rows = cursor.fetchall()

    current_table = None

    for row in rows:
        if row.TABLE_NAME != current_table:
            current_table = row.TABLE_NAME
            print(f"\n{current_table}")

        nullable = "NULL" if row.IS_NULLABLE == "YES" else "NOT NULL"
        print(
            f"  {row.COLUMN_NAME} | "
            f"{row.DATA_TYPE} | {nullable}"
        )
