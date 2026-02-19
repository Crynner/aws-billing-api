# function to make tables and for debugging functions

import boto3
import psycopg2
import json
import os
import uuid
import random
import datetime

RANDOMGEN = list('abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ')

def make_tables(rdscursor):
    print('{"msg": "Creating RDS Tables..."}')

    rdscursor.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto")
    rdscursor.execute("""CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    username VARCHAR(30) UNIQUE NOT NULL,
    email VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )""")
    rdscursor.execute("""CREATE TABLE billing_req (
    idem_key UUID PRIMARY KEY,
    status TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
    )""")
    rdscursor.execute("""CREATE TABLE account_status (
    user_id UUID PRIMARY KEY REFERENCES users(user_id),
    payment_status VARCHAR(20) NOT NULL DEFAULT 'APPROVED',
    next_payment DATE NOT NULL DEFAULT CURRENT_DATE + interval '1 month'
    )""")
    rdscursor.execute("""CREATE TABLE ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID UNIQUE NOT NULL,
    user_id UUID NOT NULL REFERENCES users(user_id),
    event_at TIMESTAMP NOT NULL DEFAULT NOW(),
    event_type TEXT NOT NULL,
    amount_cents INTEGER NOT NULL
    )""")

    # enforcing append only in ledger
    rdscursor.execute("""create function appendonly() returns trigger language plpgsql as
    $$
        begin
            return null;
        end;
    $$;""")
    rdscursor.execute("""CREATE TRIGGER ledger_append_only_trigger
    BEFORE UPDATE OR DELETE ON ledger
    FOR EACH ROW EXECUTE FUNCTION appendonly();""")

    print('{"msg": "Completed RDS Tables."}')

def get_ledger(rdscursor):
    print('{"msg": "Getting all ledger entries..."}')
    rdscursor.execute("SELECT * FROM ledger;")
    print('{"msg": "Ledger entries retrieved."}')
    return rdscursor.fetchall()

def connect_rds(secretuser, secretpass):
    return psycopg2.connect(
        host=os.environ.get('host'),
        port=int(os.environ.get('port')),
        dbname=os.environ.get('database'),
        user=secretuser,
        password=secretpass
    )

def generate_user(rdscursor):
    print('{"msg": "Creating dummy user..."}')
    userid = str(uuid.uuid4())
    name = ""
    for _ in range(random.randint(6, 20)):
        name += random.choice(RANDOMGEN)
    
    # create user
    rdscursor.execute("INSERT INTO users (user_id, username, email) VALUES (%s, %s, %s)",
        (userid,
        name,
        f"{name}@example.com")
    )

    # generate a date randomly selected from now, plus or minus one week
    random_date = datetime.date.today() + datetime.timedelta(days=random.randint(-7, 7))

    # create user account status
    rdscursor.execute("INSERT INTO account_status (user_id, next_payment) VALUES (%s, %s)", (userid,random_date))
    print('{"msg": "Dummy user created."}')

def get_random_user(rdscursor):
    # return random user id where exists in ledger
    rdscursor.execute("""
        SELECT user_id FROM users ORDER BY RANDOM() LIMIT 1;
    """)

def handler(event, context):
    client = boto3.client('secretsmanager')
    print('{"msg": "Lambda accessed Secrets Manager for RDS."}')

    get_secret_value_response = client.get_secret_value(
        SecretId=os.environ.get('secret')
    )

    secret_dict = json.loads(get_secret_value_response['SecretString'])

    conn = connect_rds(secret_dict["username"], secret_dict["password"])
    cur = conn.cursor()
    print('{"msg": "RDS connected to lambda."}')

    try:
        result = len(get_ledger(cur))

        # for i in range(100):
        #     generate_user(cur)

        print('{"msg": "RDS statements completed."}')
        conn.commit()

    except Exception as e:
        msg = {
            "msg": f"Error of type {type(e)} with message {str(e)}"
        }
        print(json.dumps(msg))
        conn.rollback()
        result = e
    finally:
        conn.close()

    return {
        'statusCode': 200,
        'body': json.dumps(f'Hello from Lambda! User is {secret_dict["username"]} and RDS returns "{result}"')
    }