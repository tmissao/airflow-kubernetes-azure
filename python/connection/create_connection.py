import json
from airflow.models.connection import Connection

# extra_dict = {}

c = Connection(
    conn_id="wasb_logs",
    conn_type="wasb",
    login="pocmissaoairflow",
    password="1GNL8WrsqJEfYWaVZrfNXn/Nnhp1PxhBPTxPuBpLbTgYIDZhQ1jqpiFQIEndEA0DJfalB8pZWlgO+ASt769BOQ==",
    #host="hooks.slack.com/services",
    # port=7077,
    #schema="https",
    # extra=json.dumps(extra_dict),
)

print(f"AIRFLOW_CONN_{c.conn_id.upper()}='{c.get_uri()}'")