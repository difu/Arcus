import sys
import json

from osgeo import gdal


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
    """ Lambda handler """
    # https://xxxxxxx.execute-api.eu-central-1.amazonaws.com/test?filename=s3://WHATEVERRASTERDATA
    print("Received event: " + json.dumps(event, indent=2))
    gdal.SetConfigOption( 'GDAL_PAM_ENABLED', 'NO' )
    fname = event["queryStringParameters"]['filename']
    fname = fname.replace('s3://', '/vsis3/')
    ds = gdal.Open(fname)
    band = ds.GetRasterBand(1)
    print(ds.GetMetadata())

    print("Rasterbands:")
    print(ds.RasterCount)

    stats = band.GetStatistics(True, True)
    the_stats={'metainformation': ds.GetMetadata(), 'min': stats[0], 'max': stats[1], 'mean': stats[2], 'stddv': stats[3]}
    print("Statistics")
    print(json.dumps(the_stats))

    print("End")
    return response(the_stats, 200)

