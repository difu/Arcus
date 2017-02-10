from httplib import HTTPSConnection
from os import makedirs, path

from django.http import (HttpResponseNotFound, StreamingHttpResponse,
                         HttpResponseRedirect)

from settings import STAGING_AREA, CACHE_SERVICE

SKY_BUCKET = "s3.eu-central-1.amazonaws.com/dwd-arcus-poc-gribs"


def stage(request, filename):
    """Stage requested resource and pass content back to caller."""
    domain, bucket = SKY_BUCKET.split("/")
    conn = HTTPSConnection(domain)
    conn.request("GET", "/{}/{}".format(bucket, filename))
    response = conn.getresponse()

    if response.status == 404:
        return HttpResponseNotFound("Sky could not locate resource.")
    contents = response.read()

    # TODO: Push contents of requested file to cache bucket
    staged_path = path.join(STAGING_AREA, filename)
    makedirs(path.dirname(staged_path))
    with open(staged_path, "w") as staged_file:
        staged_file.write(contents)

    return HttpResponseRedirect("{}/{}".format(CACHE_SERVICE, filename))
    return StreamingHttpResponse((contents))
