from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
from psycopg2 import pool
import os
import time
import uuid

app = Flask(__name__)
CORS(app)  # Enable CORS for frontend communication

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
        
        # Initialize database table
        conn = db_pool.getconn()
        cur = conn.cursor()
        cur.execute("""
            CREATE TABLE IF NOT EXISTS todos (
                id VARCHAR(50) PRIMARY KEY,
                text TEXT NOT NULL,
                completed BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        conn.commit()
        cur.close()
        db_pool.putconn(conn)
        print("✅ Database table initialized.")
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

@app.route('/api/todos', methods=['GET'])
def get_todos():
    if not db_pool:
        return jsonify({'error': 'Database connection unavailable'}), 500
    
    try:
        conn = db_pool.getconn()
        cur = conn.cursor()
        cur.execute("SELECT id, text, completed, created_at FROM todos ORDER BY created_at DESC")
        todos = []
        for row in cur.fetchall():
            todos.append({
                '_id': row[0],
                'text': row[1],
                'completed': row[2],
                'created_at': row[3].isoformat() if row[3] else None
            })
        cur.close()
        db_pool.putconn(conn)
        return jsonify(todos)
    except Exception as e:
        return jsonify({'error': f'Failed to fetch todos: {e}'}), 500

@app.route('/api/todos', methods=['POST'])
def create_todo():
    if not db_pool:
        return jsonify({'error': 'Database connection unavailable'}), 500
    
    data = request.get_json()
    if not data or 'text' not in data:
        return jsonify({'error': 'Text is required'}), 400
    
    try:
        todo_id = str(uuid.uuid4())
        conn = db_pool.getconn()
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO todos (id, text, completed) VALUES (%s, %s, %s) RETURNING id, text, completed, created_at",
            (todo_id, data['text'], False)
        )
        row = cur.fetchone()
        conn.commit()
        cur.close()
        db_pool.putconn(conn)
        
        return jsonify({
            '_id': row[0],
            'text': row[1],
            'completed': row[2],
            'created_at': row[3].isoformat() if row[3] else None
        }), 201
    except Exception as e:
        return jsonify({'error': f'Failed to create todo: {e}'}), 500

@app.route('/api/todos/<todo_id>', methods=['PATCH'])
def update_todo(todo_id):
    if not db_pool:
        return jsonify({'error': 'Database connection unavailable'}), 500
    
    data = request.get_json()
    if not data:
        return jsonify({'error': 'No data provided'}), 400
    
    try:
        conn = db_pool.getconn()
        cur = conn.cursor()
        
        # Build dynamic update query
        update_fields = []
        values = []
        
        if 'text' in data:
            update_fields.append("text = %s")
            values.append(data['text'])
        
        if 'completed' in data:
            update_fields.append("completed = %s")
            values.append(data['completed'])
        
        if not update_fields:
            return jsonify({'error': 'No valid fields to update'}), 400
        
        values.append(todo_id)
        query = f"UPDATE todos SET {', '.join(update_fields)} WHERE id = %s RETURNING id, text, completed, created_at"
        
        cur.execute(query, values)
        row = cur.fetchone()
        
        if not row:
            cur.close()
            db_pool.putconn(conn)
            return jsonify({'error': 'Todo not found'}), 404
        
        conn.commit()
        cur.close()
        db_pool.putconn(conn)
        
        return jsonify({
            '_id': row[0],
            'text': row[1],
            'completed': row[2],
            'created_at': row[3].isoformat() if row[3] else None
        })
    except Exception as e:
        return jsonify({'error': f'Failed to update todo: {e}'}), 500

@app.route('/api/todos/<todo_id>', methods=['DELETE'])
def delete_todo(todo_id):
    if not db_pool:
        return jsonify({'error': 'Database connection unavailable'}), 500
    
    try:
        conn = db_pool.getconn()
        cur = conn.cursor()
        cur.execute("DELETE FROM todos WHERE id = %s RETURNING id", (todo_id,))
        row = cur.fetchone()
        
        if not row:
            cur.close()
            db_pool.putconn(conn)
            return jsonify({'error': 'Todo not found'}), 404
        
        conn.commit()
        cur.close()
        db_pool.putconn(conn)
        
        return jsonify({'message': 'Todo deleted successfully'})
    except Exception as e:
        return jsonify({'error': f'Failed to delete todo: {e}'}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)