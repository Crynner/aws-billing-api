import json
import boto3
import psycopg2
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

    # check if user_id exists
    cur.execute("SELECT * FROM users WHERE user_id = %s", (event["pathParameters"]["id"],))
    # return failure if id doesnt exist
    if not cur.fetchone():
        print('{"msg": "Queried id does not exist."}')
        return {
            'statusCode': 400,
            "headers": {
                "Content-Type": "application/json"
            },
            'body': json.dumps('User ID does not exist')
        }

    try:
        # if link has balance in path, return balance function
        if "balance" in event["routeKey"]:
            return get_balance(cur, event["pathParameters"]["id"])
        # other case, return ledger function
        return get_ledger(cur, event["pathParameters"]["id"])

    except Exception as e:
        msg = {
            "level": "error",
            "msg": f"Error of type {type(e)} with message {str(e)}"
        }
        print(json.dumps(msg))
        conn.rollback()
        raise
    return {
        'statusCode': 200,
        "headers": {
            "Content-Type": "application/json"
        },
        'body': json.dumps('Worked Successfully!')
    }


def get_balance(rdscursor, user_id):
    print('{"msg": "Retrieving user balance..."}')
    # get and return status code of account via userid
    rdscursor.execute("SELECT payment_status FROM account_status WHERE user_id = %s", (user_id,))
    return {
        'statusCode': 200,
        "headers": {
            "Content-Type": "application/json"
        },  
        'body': json.dumps(rdscursor.fetchone())
    }


def get_ledger(rdscursor, user_id):
    print('{"msg": "Retrieving user ledger data..."}')
    # get ledger data where user id matches
    rdscursor.execute("SELECT * FROM ledger WHERE user_id = %s", (user_id, ))
    #parse cursor data into list of json objects as response
    return {
        'statusCode': 200,
        'body': json.dumps(rdscursor.fetchall())
    }

    