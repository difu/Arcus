import json
import sys

sys.path.append("/opt/")
import os

from osgeo import gdal, osr, gdal_array
import numpy as np


def lambda_handler(event, context):
    gdal.SetConfigOption('GDAL_PAM_ENABLED', 'NO')
    # #filename="s3://landsat-pds/L8/001/002/LC80010022016230LGN00/LC80010022016230LGN00_B3.TIF"
    # fname = event["queryStringParameters"]['filename']
    # fname = fname.replace('s3://', '/vsis3/')
    # #
    # ds = gdal.Open(fname, gdal.GA_ReadOnly)
    # #    print(ds, ds.RasterCount)
    # band = ds.GetRasterBand(1)
    # srs = osr.SpatialReference()
    # srs.ImportFromWkt(ds.GetProjection())
    #
    # srsLatLong = srs.CloneGeogCS()
    # # Mainz
    # latitude = 50
    # longitude = 8
    # ct = osr.CoordinateTransformation(srsLatLong, srs)
    # (X, Y, height) = ct.TransformPoint(longitude, latitude)
    # geomatrix = ds.GetGeoTransform()
    # inv_geometrix = gdal.InvGeoTransform(geomatrix)
    # x = int(inv_geometrix[0] + inv_geometrix[1] * X + inv_geometrix[2] * Y)
    # y = int(inv_geometrix[3] + inv_geometrix[4] * X + inv_geometrix[5] * Y)
    # res = ds.ReadAsArray(x, y, 1, 1)

    return {
        'statusCode': 200,
        'body': 'series'
    }

