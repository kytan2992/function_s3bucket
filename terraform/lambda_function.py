import json

def lambda_handler(event, context):
    # TODO implement
    print("event:")
    print(event)
    print("context:")
    print(context)
    return {
        'statusCode': 200,
        'body': json.dumps('Hello from Lambda!')
    }