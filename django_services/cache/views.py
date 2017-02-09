import datetime
import md5
import re
from httplib import HTTPSConnection
from mimetypes import MimeTypes
from os import path
from string import ljust

from django.http import HttpResponse, HttpResponseBadRequest, HttpResponseNotFound

ARCHIVE = path.expanduser("~/archive")
STAGING_AREA = path.expanduser("~/stage")
GRIB_LENGTH = 1397695
VALID_IDS = ("10u", "10v", "2t", "sp")
TIME_RANGE = ("1995010101", "1995013123")
TIME_FORMAT = "%Y%m%d%H"
SUBSET_PATTERN = """
^
[tx-z]
\(
(
 \d+
 |
  (\d+|\*)+
  ,
  (\d+|\*)
)
\)
"""


def index(request):
    return HttpResponse("Hello DWD, welcome to my index.")


def response_from_file(filename):
    """Generate well-formed HTTPResponse from a file."""
    content_type = MimeTypes().guess_type(filename)
    with open(filename) as my_file:
        return HttpResponse(my_file.read(), content_type=content_type)


def stage(request, filename):
    """Stage a requested file."""
    print("staging file")
    full_path = path.join(ARCHIVE, filename)
    if not path.exists(full_path):
        return HttpResponseNotFound("Resource not found in archive.")
    response = response_from_file(full_path)
    staged_path = path.join(STAGING_AREA, filename)
    with open(staged_path, "w") as staged_file:
        staged_file.write(response.content)
    return response


def get_resource(request, filename):
    """Return the content of a file if it's in the staging area."""
    full_path = path.join(STAGING_AREA, filename)
    if not path.exists(full_path):
        response = stage(request, filename)
    else:
        response = response_from_file(full_path)
    return response


def subset_is_valid(subset):
    """Subset is well-formed."""
    return re.search(SUBSET_PATTERN, subset, re.VERBOSE) is not None


def parse_time_subset(request):
    """Find timestamps touched by time subset."""
    available_times = TIME_RANGE[0], TIME_RANGE[1]
    # Extract boundaries
    request = [request[request.index("(") + 1 : request.index(",")],
               request[request.index(",") + 1 : -1]]

    for x in request:
        if len(x) < 4 or not x.isdigit():
            raise TypeError("Time steps should be formatted: YYYY[MM][DD][HH]")

    for i in range(len(request)):
        if request[i] == "*":
            request[i] = available_times[i]

    # Dates are formatted %Y%m%d%H
    if len(request[0]) < 10: request[0] = ljust(request[0], 10, "0")
    if len(request[1]) < 10:
        request[1] = ljust(request[1], 8, "0") + "23"

    # Requested dates are within available time boundary
    for i, op in zip((0, 1), (str.__lt__, str.__gt__)):
        if op(str(request[i]), available_times[i]):
            request[i] = available_times[i]

    for i in range(len(request)):
        request[i] = datetime.datetime.strptime(request[i], TIME_FORMAT)

    requested_timestamps = []
    timestamp = request[0]
    while timestamp <= request[1]:
        requested_timestamps.append(timestamp.strftime(TIME_FORMAT))
        timestamp += datetime.timedelta(hours=1)
    return requested_timestamps


class RequestedResource(object):

    """A requested GRIB resource defined by URI and byte range."""

    def __init__(self, timestamps, layer,
                 domain="s3.eu-central-1.amazonaws.com",
                 bucket="dwd-arcus-poc-gribs"):
        """Discover resources to be requested."""
        requested_day = timestamps[0][:8]
        if not all([x.startswith(requested_day) for x in timestamps]):
            raise RuntimeError("A RequestedResource should contain only 1 day.")
        resource_name = "{day}/{layer}.grb2".format(day=requested_day,
                                                    layer=layer)
        md5_summer = md5.new()
        md5_summer.update(resource_name)
        hours = [x[-2:] for x in timestamps]

        self.remote_domain = domain
        self.bucket = bucket
        #: e.g. 853a/19950101/10u.grb2
        self.uri = "/{hash}/{name}".format(hash=md5_summer.hexdigest()[:4],
                                           name=resource_name)
        #: e.g. 0-299
        self.byte_range = "{}-{}".format(min(hours) * GRIB_LENGTH,
                                         max(hours) * GRIB_LENGTH)

    def request(self):
        conn = HTTPSConnection(self.remote_domain)
        conn.request("GET", self.bucket + self.uri,
                     headers={"Range": "bytes={}".format(self.byte_range)})
        response = conn.getresponse()
        return response.read()


def wcs(request):
    """Entry point for a WCS request."""
    service = request.GET["service"]
    req_type = request.GET["request"]
    if not service.lower() == "wcs" or not req_type.lower() == "getcoverage":
        return HttpResponseBadRequest("Only WCS:GetCoverage requests are "
                                      "supported.")

    id_list = request.GET["coverageId"].split(",")
    if not set(id_list) <= set(VALID_IDS):
        return HttpResponseNotFound("Requested coverageId not found. Valid "
                                    "coverageIds: {}".format(VALID_IDS))

    subsets = request.GET.getlist("subset")
    for subset in subsets:
        if not subset_is_valid(subset):
            return HttpResponseBadRequest("Invalid subsetting syntax.")

    version = request.GET["version"]
    if version != "2.0":
        return HttpResponseBadRequest("Only WCS 2.0 requests supported.")

    time_subsets = [x for x in subsets if x.startswith("t")]
    requested_times = []
    for time_subset in time_subsets:
        requested_times += parse_time_subset(time_subset)

    """
    Form requests. You do this by consuming requested_times day by day. Pass
    them all in to a RequestedResource, which you keep in a list. Then at the
    end of it all you can use the RequestedResource's request method to pull
    back the data and send it buffered to the user.
    Do this in a loop over the layers. One layer should return all timestamps
    before the next layer is begun.
    Preliminary check:
    rr = RequestedResource(some_timestamps, "2t")
    print(rr.remote_domain + "/" + rr.bucket + rr.uri)
    """

    response = """
    Service: {s} <br>
    Version: {v} <br>
    Request: {r} <br>
    Layer IDs: {i} <br>
    Subsets: {sub}
    <p>
    Time subsets: {time_subs}
    <p>
    Requested times: {times}
    """.format(s=service, v=version, r=req_type, i=id_list, sub=subsets,
               time_subs=time_subsets, times=requested_times)

    return HttpResponse(response)

