import getpass
import psycopg

print("Render PostgreSQL account checker")
print("----------------------------------")

database_url = getpass.getpass(
    "postgresql://name_ai_sports_talent_db_user:Qg4F0CYAQh2LWFgfc67rC9zBlimnNpWA@dpg-dapv99mgekts73fbj900-a.oregon-postgres.render.com/name_ai_sports_talent_db "
)

try:
    with psycopg.connect(
        database_url,
        sslmode="require",
    ) as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                SELECT id, username, email, role
                FROM users
                WHERE username = %s;
                """,
                ("akshatkapoor",),
            )

            row = cur.fetchone()

            if row is None:
                print("\nRESULT: USER NOT FOUND")
                print(
                    "The account 'akshatkapoor' does not exist "
                    "in this Render database."
                )
            else:
                print("\nRESULT: USER FOUND")
                print(f"ID: {row[0]}")
                print(f"Username: {row[1]}")
                print(f"Email: {row[2]}")
                print(f"Role: {row[3]}")

except Exception as e:
    print("\nDATABASE CONNECTION ERROR:")
    print(type(e).__name__)
    print(str(e))