import json
from airflow.models.connection import Connection

# extra_dict = {}

c = Connection(
    conn_id="wasb_logs",
    conn_type="wasb",
    login="pocmissaoairflow",
    password="ge98H85rpuLdvVbe+ias/W6JMHZRFflYa0fZaS9+pgzvZH006mTnkqoXJhnRObixbGYyEfpNr9J2+AStyqXd+A==",
    #host="hooks.slack.com/services",
    # port=7077,
    #schema="https",
    # extra=json.dumps(extra_dict),
)

print(f"AIRFLOW_CONN_{c.conn_id.upper()}='{c.get_uri()}'")