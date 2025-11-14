from flask import Flask, jsonify, request
import os, psycopg2
app = Flask(__name__)
DB_URL = os.environ.get("DATABASE_URL","postgresql://demo:demopw@postgres:5432/bankdb")
def get_conn():
    return psycopg2.connect(DB_URL)
@app.route('/')
def index():
    return "Banking demo - env: " + os.environ.get("FLASK_ENV","dev")
@app.route('/transactions')
def transactions():
    conn = get_conn()
    cur = conn.cursor()
    cur.execute("CREATE TABLE IF NOT EXISTS transactions (id varchar PRIMARY KEY, amount numeric, type varchar);")
    cur.execute("SELECT id, amount, type FROM transactions LIMIT 100;")
    rows = cur.fetchall()
    cur.close(); conn.close()
    return jsonify([{'id': r[0], 'amount': float(r[1]), 'type': r[2]} for r in rows])
@app.route('/pay', methods=['POST'])
def pay():
    payload = request.json or {}
    import requests
    pg_url = os.environ.get("PAYMENT_GATEWAY_URL","http://mockserver:1080")
    r = requests.post(pg_url + "/mocked/payment", json=payload, timeout=5)
    return (r.text, r.status_code, {'Content-Type': 'application/json'})
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
