
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

try:
    with pyodbc.connect(connection_string, timeout=10) as connection:
        cursor = connection.cursor()
        cursor.execute("SELECT DB_NAME()")
        print("Connected successfully!")
        print("Database:", cursor.fetchone()[0])

except pyodbc.Error as error:
    print("Connection failed:")
    print(error)
