from httplib import HTTPConnection
from mimetypes import MimeTypes
from os import path

from django.http import StreamingHttpResponse, HttpResponseNotFound

from settings import STAGING_AREA, SKY_SERVICE


def response_from_file(filename, http_range):
    """Generate well-formed HTTPResponse from a file."""
    content_type = MimeTypes().guess_type(filename)
    begin, end = http_range
    with open(filename) as my_file:
        my_file.seek(begin)
        return StreamingHttpResponse([my_file.read(end - begin)],
                                     content_type=content_type)


def get_by_http(domain, path):
    """Do the legwork of a HTTP request."""
    conn = HTTPConnection(domain)
    conn.request("GET", path)
    return conn.getresponse()


def get_resource(request, filename):
    """Return the content of a file if it's in the staging area."""
    http_range = request.META.get("HTTP_RANGE")
    http_range = http_range.split("=")[1].split("-")
    http_range = int(http_range[0]), int(http_range[1])
    full_path = path.join(STAGING_AREA, filename)
    
    if not path.exists(full_path):
        domain, service = SKY_SERVICE.split("/")
        response = get_by_http(domain, "/{}/{}".format(service, filename))
        # Sky serviced cached request, try again
        if response.status == 302:
            response = get_by_http(domain, "/{}/{}".format(service, filename))
            response = StreamingHttpResponse((response.read()))
        elif response.status == 404:
            return HttpResponseNotFound("Sky could not locate resource.")
    else:
        response = response_from_file(full_path, http_range)
    return response
