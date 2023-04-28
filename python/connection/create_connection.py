import json
from airflow.models.connection import Connection

# extra_dict = {}

c = Connection(
    conn_id="slack_conn",
    conn_type="slackwebhook",
    # login="hive",
    password="T04LZFUE80G/B04LZHCBW56/myTs1kwce7xhNvBGvb3HDbv0",
    host="hooks.slack.com/services",
    # port=7077,
    schema="https",
    # extra=json.dumps(extra_dict),
)

print(f"AIRFLOW_CONN_{c.conn_id.upper()}='{c.get_uri()}'")