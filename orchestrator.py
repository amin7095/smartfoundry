#!/usr/bin/env python3
import os, json, tarfile, tempfile, requests
TFC_API = "https://app.terraform.io/api/v2"
TFC_TOKEN = os.getenv("TFC_TOKEN"); TFC_ORG = os.getenv("TFC_ORG"); TFC_WORKSPACE = os.getenv("TFC_WORKSPACE","env-on-demand")
headers = {"Authorization": f"Bearer {TFC_TOKEN}", "Content-Type": "application/vnd.api+json"}
def tfc_workspace_id():
    r = requests.get(f"{TFC_API}/organizations/{TFC_ORG}/workspaces/{TFC_WORKSPACE}", headers=headers); r.raise_for_status(); return r.json()['data']['id']
def upload_config(ws_id):
    r = requests.post(f"{TFC_API}/workspaces/{ws_id}/configuration-versions", headers=headers); r.raise_for_status(); data = r.json()['data']; cv = data['id']; upload_url = data['attributes']['upload-url']
    with tempfile.NamedTemporaryFile(suffix='.tar.gz', delete=False) as tmp:
        with tarfile.open(tmp.name, 'w:gz') as tar:
            tar.add('terraform', arcname='.')
        with open(tmp.name,'rb') as f:
            requests.put(upload_url, data=f)
    return cv
def set_vars(ws_id, vars_map):
    for k,v in vars_map.items():
        body = { "data": {"type":"vars","attributes":{"key":k,"value":str(v),"category":"terraform","hcl":False,"sensitive": False}}}
        requests.post(f"{TFC_API}/workspaces/{ws_id}/vars", headers=headers, data=json.dumps(body))
def trigger_run(ws_id, cv, msg, destroy=False):
    body = {"data":{"attributes":{"message":msg,"auto-apply":True,"is-destroy":destroy},"type":"runs","relationships":{"workspace":{"data":{"type":"workspaces","id":ws_id}},"configuration-version":{"data":{"type":"configuration-versions","id":cv}}}}}
    r = requests.post(f"{TFC_API}/runs", headers=headers, data=json.dumps(body)); r.raise_for_status(); return r.json()['data']['id']
if __name__ == '__main__':
    import argparse
    p = argparse.ArgumentParser(); p.add_argument('--action',choices=['create','destroy'],required=True); p.add_argument('--env',required=True); args = p.parse_args()
    ws = tfc_workspace_id(); cv = upload_config(ws)
    vars_map = {
        "env_name": args.env,
        "app_repo": os.getenv('APP_REPO','none'),
        "aws_region": os.getenv('AWS_REGION','us-east-1'),
        "subnet_id": os.getenv('SUBNET_ID',''),
        "vpc_id": os.getenv('VPC_ID',''),
        "instance_type": os.getenv('INSTANCE_TYPE','t3.medium'),
        "ssh_public_key": os.getenv('SSH_PUBLIC_KEY',''),
        "datadog_api_key": os.getenv('DD_API_KEY',''),
        "gremlin_team_id": os.getenv('GREMLIN_TEAM_ID',''),
        "gremlin_secret": os.getenv('GREMLIN_SECRET',''),
        "db_username": os.getenv('DB_USERNAME','demo'),
        "db_password": os.getenv('DB_PASSWORD','demopw'),
        "payment_mode": os.getenv('PAYMENT_MODE','mock'),
        "dynamodb_table_name": os.getenv('DYNAMODB_TABLE','')
    }
    set_vars(ws, vars_map)
    run_id = trigger_run(ws, cv, f"Provision env {args.env}", destroy=(args.action=='destroy'))
    print('Triggered run', run_id)
