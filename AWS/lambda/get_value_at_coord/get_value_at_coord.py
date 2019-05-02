import json
import sys
import boto3
from datetime import datetime

sys.path.append("/opt/")
import os

from osgeo import gdal, osr, gdal_array
import numpy as np


def lambda_handler(event, context):
    print(os.environ['LD_LIBRARY_PATH'])
    gdal.SetConfigOption('GDAL_PAM_ENABLED', 'NO')
    # filename="s3://landsat-pds/L8/001/002/LC80010022016230LGN00/LC80010022016230LGN00_B3.TIF"
    if 'action' in event["queryStringParameters"]:
        if event["queryStringParameters"]["action"] == "timeseries":
            return return_timeseries(event)
    else:
        print("Action NOT taken")

    print("After Action")

    fname = event["queryStringParameters"]['filename']
    fname = fname.replace('s3://', '/vsis3/')
    ds = gdal.Open(fname, gdal.GA_ReadOnly)
    #    print(ds, ds.RasterCount)
    band = ds.GetRasterBand(1)
    srs = osr.SpatialReference()
    srs.ImportFromWkt(ds.GetProjection())

    srsLatLong = srs.CloneGeogCS()
    # Mainz
    latitude = 50
    longitude = 8
    ct = osr.CoordinateTransformation(srsLatLong, srs)
    (X, Y, height) = ct.TransformPoint(longitude, latitude)
    geomatrix = ds.GetGeoTransform()
    inv_geometrix = gdal.InvGeoTransform(geomatrix)
    x = int(inv_geometrix[0] + inv_geometrix[1] * X + inv_geometrix[2] * Y)
    y = int(inv_geometrix[3] + inv_geometrix[4] * X + inv_geometrix[5] * Y)
    res = ds.ReadAsArray(x, y, 1, 1)

    return {
        'statusCode': 200,
        'body': '1,2\n2,4\5,7\n'
    }

    return {
        'statusCode': 200,
        'body': json.dumps(band.GetMetadata())
    }

    return {
        'statusCode': 200,
        'body': json.dumps(res[0][0])
    }


def get_matching_s3_keys(bucket, prefix='', suffix=''):
    s3res = boto3.resource('s3')
    the_bucket = s3res.Bucket(bucket)
    objects = []
    for obj in the_bucket.objects.filter(Prefix=prefix):
        objects.append(obj.key)
    return objects


def return_timeseries(event):
    bucket = event["queryStringParameters"]["bucket"]
    bucket_dir = event["queryStringParameters"]["bucketDir"]
    start_index = event["queryStringParameters"]["start"]
    stop_index = event["queryStringParameters"]["stop"]
    lat, long = get_long_lat_from_event(event)
    the_keys = get_matching_s3_keys(bucket, bucket_dir)[int(start_index): int(stop_index) + 1]

    timeseries = []
    for key in the_keys:
        fname = "/vsis3/" + bucket + "/" + key
        ds = gdal.Open(fname, gdal.GA_ReadOnly)
        band = ds.GetRasterBand(1)
        # datetime.utcfromtimestamp(ts).strftime('%Y-%m-%d %H:%M:%S')
        the_val = get_value_from_lat_long(ds, lat, long)
        the_timestamp = band.GetMetadata()["GRIB_VALID_TIME"]  # "GRIB_VALID_TIME": "  1548712800 sec UTC"
        the_timestamp = [int(s) for s in the_timestamp.split() if s.isdigit()][0]
        the_date = datetime.utcfromtimestamp(the_timestamp).strftime('%Y/%m/%d %H:%M:%S')
        the_element = [the_date, the_val]
        timeseries.append(the_element)
        # timeseries.append(fname)

    if 'format' in event["queryStringParameters"]:
        if event["queryStringParameters"]["format"] == "csv":
            csv = ""
            for element in timeseries:
                csv += str(element[0]) + ", " + str(element[1]) + "\n"

            return {
                'statusCode': 200,
                'headers': {"content-type": "text/comma-separated-values", 'Access-Control-Allow-Origin': '*'},
                'body': csv
            }

    return {
        'statusCode': 200,
        'body': json.dumps(timeseries)
    }


def get_long_lat_from_event(event, default_lat=50, default_long=8):
    return default_lat, default_long


def get_value_from_lat_long(dataset, lat, long):
    srs = osr.SpatialReference()
    srs.ImportFromWkt(dataset.GetProjection())

    srsLatLong = srs.CloneGeogCS()

    latitude = lat
    longitude = long
    ct = osr.CoordinateTransformation(srsLatLong, srs)
    (X, Y, height) = ct.TransformPoint(longitude, latitude)
    geomatrix = dataset.GetGeoTransform()
    inv_geometrix = gdal.InvGeoTransform(geomatrix)
    x = int(inv_geometrix[0] + inv_geometrix[1] * X + inv_geometrix[2] * Y)
    y = int(inv_geometrix[3] + inv_geometrix[4] * X + inv_geometrix[5] * Y)
    res = dataset.ReadAsArray(x, y, 1, 1)
    return res[0][0]
