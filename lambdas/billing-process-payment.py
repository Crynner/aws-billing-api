import json
import boto3
import psycopg2
import uuid
import os

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

    get_secret_value_response = rds_client.get_secret_value(
        SecretId=os.environ.get('secret')
    )

    secret_dict = json.loads(get_secret_value_response['SecretString'])

    conn = connect_rds(secret_dict["username"], secret_dict["password"])
    cur = conn.cursor()

    print('{"msg": "Lambda connected to RDS."}')

    try:
        # each message (one per lambda),
        for record in event['Records']:

            data = json.loads(record['body'])
            # add to billing_req
            cur.execute("INSERT INTO billing_req (idem_key, status) VALUES (%s, %s) ON CONFLICT (idem_key) DO NOTHING", (data['idem_key'], 'PENDING'))
            cur.execute("UPDATE account_status SET payment_status = 'PENDING' WHERE user_id = %s", (data['user_id'],))

            # precheck where to execute from based on billing_req status
            cur.execute("SELECT status FROM billing_req WHERE idem_key = %s", (data['idem_key'], ))
            record_status = cur.fetchone()[0]
            
            if record_status == 'PENDING':
                payment_uuid = str(uuid.uuid5(uuid.NAMESPACE_URL, f"{data['user_id']}-{data["billed_date"]}-mockpayment"))
                # add payment to ledger (check if thats how it works)
                cur.execute("INSERT INTO ledger (user_id, event_id, event_type, amount_cents) VALUES (%s, %s, %s, %s)", (data['user_id'], payment_uuid, 'mockpayment', 1000))
                print("Mock Payment Process...")

                # change account status
                cur.execute("UPDATE account_status SET payment_status = 'INVOICING' WHERE user_id = %s", (data['user_id'],))
                record_status = 'INVOICING'

            if record_status == 'INVOICING':
                # set idem key to invoicing stage
                cur.execute("UPDATE billing_req SET status = 'INVOICING' WHERE idem_key = %s", (data['idem_key'],))

                # complete billing req (e.g. invoicing stage)
                # invoicing
                print("Creating invoice...")

                # set idem key to completed
                cur.execute("UPDATE billing_req SET status = 'completed' WHERE idem_key = %s", (data['idem_key'], ))
                cur.execute("UPDATE account_status SET payment_status = 'APPROVED' WHERE user_id = %s", (data['user_id'], ))
                
                # # Key idempotency by billing_req state checking
                print('{"msg": "Lambda completed successfully."}')
                conn.commit()  

    except Exception as e:
        msg = {
            "level": "error",
            "msg": f"Error of type {type(e)} with message {str(e)}"
        }
        print(json.dumps(msg))
        conn.rollback()
        conn.close()
        raise
    conn.close()

    # TODO implement
    return {
        'statusCode': 200,
        'body': json.dumps(f'Lambda exiting...')
    }
