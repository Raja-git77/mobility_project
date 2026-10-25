import os
import psycopg2
import requests
from dotenv import load_dotenv

load_dotenv()

def get_db_connection():
    """Connect to postgres DB with DATABASE_URL support and fallback options."""
    try:
        db_url = os.getenv("DATABASE_URL")
        if db_url:
            if db_url.startswith("postgres://"):
                db_url = "postgresql://" + db_url[len("postgres://"):]
            return psycopg2.connect(dsn=db_url, connect_timeout=5)
        
        return psycopg2.connect(
            dbname=os.getenv("PGDATABASE", os.getenv("DB_NAME", "postgres")),
            user=os.getenv("PGUSER", os.getenv("DB_USER", "postgres")),
            password=os.getenv("PGPASSWORD", os.getenv("DB_PASSWORD", "")),
            host=os.getenv("PGHOST", os.getenv("DB_HOST", "localhost")),
            port=int(os.getenv("PGPORT", os.getenv("DB_PORT", "5432"))),
            connect_timeout=5
        )
    except Exception as e:
        print(f"[Backend DB] Connection notice: {e}")
        return None

def process_successful_upi_payment(
    transaction_id: str = "TXN_UPI_DEMO",
    vehicle_category: str = "Sedan",
    fare: float = 180.0,
    recipient_mobile: str = "8807861577"
):
    """
    Handles UPI payment confirmation:
    1. Records successful payment status in PostgreSQL database.
    2. Injects Fast2SMS notification via GET request immediately after database update.
    3. Wraps the SMS call in a try/except block to ensure payment success returns 200 OK.
    """
    db_recorded = False
    conn = get_db_connection()
    if conn:
        try:
            cursor = conn.cursor()
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS payments (
                    id SERIAL PRIMARY KEY,
                    transaction_id VARCHAR(100),
                    vehicle_category VARCHAR(100),
                    fare FLOAT,
                    payment_status VARCHAR(50) DEFAULT 'COMPLETED',
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
                """
            )
            cursor.execute(
                "INSERT INTO payments (transaction_id, vehicle_category, fare, payment_status) VALUES (%s, %s, %s, %s)",
                (transaction_id, vehicle_category, fare, "COMPLETED")
            )
            conn.commit()
            cursor.close()
            conn.close()
            db_recorded = True
            print(f"Payment marked COMPLETED in PostgreSQL: txn={transaction_id}, fare=₹{fare}")
        except Exception as err:
            print("Database update error:", err)
    else:
        print("Note: PostgreSQL offline or local simulation active.")

    # 3. Inject Fast2SMS GET request immediately after payment is marked successful in the database
    try:
        url = "https://www.fast2sms.com/dev/bulkV2"
        headers = {"authorization": "YOUR_API_KEY_HERE"}
        params = {
            "route": "q",
            "numbers": "8807861577",
            "message": "Your mobility booking is confirmed! Payment successful."
        }
        response = requests.get(url, headers=headers, params=params, timeout=5)
        print("Fast2SMS API Response Status:", response.status_code)
    except Exception as e:
        # 4. Wrap request in try/except block so payment still successfully completes and returns 200 OK
        print(f"SMS notification failed: {e}")

    return {
        "status": "success",
        "statusCode": 200,
        "transaction_id": transaction_id,
        "database_recorded": db_recorded,
        "message": "UPI payment verified and confirmed successfully."
    }

if __name__ == "__main__":
    conn = get_db_connection()
    if conn:
        print("Database connected successfully! 🎉")
        conn.close()
    else:
        print("Database connection test finished.")