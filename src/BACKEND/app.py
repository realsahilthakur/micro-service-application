from flask import Flask, jsonify
import psycopg2
from psycopg2 import pool
import os
import time

app = Flask(__name__)

db_host = os.getenv("DB_HOST", "db")

# Database connection pool with retry logic
db_pool = None
for attempt in range(5):
    try:
        db_pool = psycopg2.pool.SimpleConnectionPool(
            1, 20,
            host=db_host,
            port="5432",
            database="mydb",
            user="user",
            password="pass"
        )
        print("✅ Connected to database.")
        break
    except Exception as e:
        print(f"⏳ Attempt {attempt + 1}: Failed to connect to database: {e}")
        time.sleep(3)

if not db_pool:
    print("❌ All retries failed. Database connection unavailable.")

@app.route('/')
def index():
    if db_pool:
        try:
            conn = db_pool.getconn()
            cur = conn.cursor()
            cur.execute("SELECT 'Hello from the backend!'")
            message = cur.fetchone()[0]
            cur.close()
            db_pool.putconn(conn)
            return jsonify({'message': message})
        except Exception as e:
            return jsonify({'error': f'Database query failed: {e}'}), 500
    else:
        return jsonify({'error': 'Database connection unavailable'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
