#!/usr/bin/env python3
import boto3, os, argparse, psycopg2
from boto3.dynamodb.conditions import Key
p = argparse.ArgumentParser(); p.add_argument('--target', required=True); p.add_argument('--env', required=True); args = p.parse_args()
ddb = boto3.resource('dynamodb', region_name=os.environ.get('AWS_REGION','us-east-1'))
table_name = os.environ.get('DDB_TABLE','') or '${DDB_TABLE}'
table = ddb.Table(table_name)
resp = table.query(KeyConditionExpression=Key('env_name').eq(args.env))
items = resp.get('Items', [])
conn = psycopg2.connect(args.target); cur = conn.cursor()
cur.execute("CREATE TABLE IF NOT EXISTS transactions (id varchar PRIMARY KEY, amount numeric, type varchar);")
for item in items:
    if item.get('sort_key','').startswith('transaction'):
        cur.execute("INSERT INTO transactions (id, amount, type) VALUES (%s,%s,%s) ON CONFLICT DO NOTHING",
                    (item.get('txn_id'), item.get('amount'), item.get('type')))
conn.commit(); cur.close(); conn.close()
print('Seeded', len(items), 'items from DynamoDB')
