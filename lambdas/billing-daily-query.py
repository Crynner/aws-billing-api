import json
import os
import psycopg2
import boto3
import uuid

queue_url = os.environ.get('queue')

def connect_rds(secretuser, secretpass):
    return psycopg2.connect(
        host=os.environ.get('host'),
        port=int(os.environ.get('port')),
        dbname=os.environ.get('database'),
        user=secretuser,
        password=secretpass
    )

def handler(event, context):
    rds_client = boto3.client('secretsmanager')
    sqs_client = boto3.client('sqs')

    get_secret_value_response = rds_client.get_secret_value(
        SecretId=os.environ.get('secret')
    )

    secret_dict = json.loads(get_secret_value_response['SecretString'])

    conn = connect_rds(secret_dict["username"], secret_dict["password"])
    cur = conn.cursor()

    print('{"msg": "Lambda connected to RDS."}')
    
    try:
        cur.execute("SELECT * FROM account_status WHERE next_payment <= CURRENT_DATE;")
        for row in cur.fetchall():
            message = {
                "idem_key": str(uuid.uuid5(uuid.NAMESPACE_URL, f'{row[0]}-{row[2].isoformat()}')),
                "user_id": row[0],
                "billed_date": row[2].isoformat(),
                "event_type": "select_charge"
            }

            # inform ledger
            cur.execute("INSERT INTO ledger(user_id, event_id, event_type, amount_cents) VALUES(%s, %s, %s, %s);", (message["user_id"], message["idem_key"], message["event_type"], 0))

            # send message to queue
            sqs_client.send_message(
                QueueUrl=queue_url,
                MessageBody=json.dumps(message)
            )
        conn.commit()
        result = "success"
    except Exception as e:
        msg = {
            "level": "error",
            "msg": f"Error of type {type(e)} with message {str(e)}"
        }
        print(json.dumps(msg))
        conn.rollback()
        raise
    finally:
        print('{"msg": "Lambda completed successfully."}')
        conn.close()

    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps(f'Result: {result}')
    }


