import json
import boto3
import psycopg2
import os
import uuid

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
        data = json.loads(event["body"]) # with username and email fields

        # check if username or email already exists in users
        cur.execute("SELECT * FROM users WHERE username = %s OR email = %s;", (data["username"], data["email"]))
        # if username or email exists, throw error
        if cur.fetchone() is not None:
            raise Exception("Username or email already exists.")

        user_id = str(uuid.uuid4())
        cur.execute("INSERT INTO users (user_id, username, email) VALUES (%s, %s, %s);", (user_id, data["username"], data["email"]))
        cur.execute("INSERT INTO account_status(user_id) VALUES (%s);", (user_id, ))
        
    except Exception as e:
        msg = {
            "level": "error",
            "msg": f"Error of type {type(e)} with message {str(e)}"
        }
        print(json.dumps(msg))
        conn.rollback()
        conn.close()
        raise

    print('{"msg": "Lambda completed successfully"}')
    conn.commit()
    conn.close()
    
    return {
        "statusCode": 201,
        "headers": {
            "Content-Type": "application/json",
            "Location": f"/users/{user_id}"
        },
        "body": json.dumps({
            "user_id": user_id,
            "account_status": "ACTIVE"
        })
    }
