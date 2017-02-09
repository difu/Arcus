from os import path
from mimetypes import MimeTypes
import re

from django.http import HttpResponse, Http404


ARCHIVE = path.expanduser("~/archive")
STAGING_AREA = path.expanduser("~/stage")
GRIB_LENGTH = 1397695
VALID_IDS = ["10u", "10v", "2t", "sp"]
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
        raise Http404()
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


# TODO: Formalize tests. Assert is good for now, but correct errors needed, etc.
def wcs(request):
    """Entry point for a WCS request."""
    service = request.GET["service"]
    req_type = request.GET["request"]
    assert(service.lower() == "wcs" and req_type.lower() == "getcoverage")

    id_list = request.GET["id"].split(",")
    assert(set(id_list) <= set(VALID_IDS))

    subsets = [request.GET[x] for x in request.GET.keys()
               if x.startswith("subset")]
    for subset in subsets: assert(subset_is_valid(subset))
    version = request.GET["version"]

    response = """
    Service: {s} <br>
    Version: {v} <br>
    Request: {r} <br>
    Layer IDs: {i} <br>
    Subsets: {sub}
    """.format(s=service, v=version, r=req_type, i=id_list, sub=subsets)

    return HttpResponse(response)

