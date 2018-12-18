from __future__ import print_function

import boto3
from botocore.client import Config
import json

s3 = boto3.client('s3', 'eu-central-1', config=Config(s3={'addressing_style': 'path'}))


def response(message, status_code):
    return {
        'statusCode': str(status_code),
        'body': json.dumps(message),
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
            },
        }


def lambda_handler(event, context):
    # Get the object from the event and show its content type
    #    bucket = event['Records'][0]['s3']['bucket']['name']
    #    key = event['Records'][0]['s3']['object']['key']
    try:
        print("Received event: " + json.dumps(event, indent=2))
        # https://*****.execute-api.eu-central-1.amazonaws.com/test/getmetadata/geotiff1.gtiff?layer=1
        # {"layer": "1", "path": "/getmetadata/geotiff1.gtiff"}
        resp = {'layer': event["queryStringParameters"]['layer'],
                'path': event["path"]}
        return response(resp, 200)

    except Exception as e:
        print(e)
        print('Error1')
        raise e
