from os import path
from mimetypes import MimeTypes

from django.http import HttpResponse, Http404


ARCHIVE = path.expanduser("~/archive")
STAGING_AREA = path.expanduser("~/stage")


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


def wcs(request):
    """Entry point for a WCS request."""
    service = request.GET["service"]
    version = request.GET["version"]
    req_type = request.GET["request"]
    id_list = request.GET.getlist("id")
    subsets = {}
    for x in request.GET.keys():
       if x.startswith("subset"):
            subsets[x] = request.GET[x]
    assert(service.lower() == "wcs" and req_type.lower() == "getcoverage")

    response = """
    Service: {s} <br>
    Version: {v} <br>
    Request: {r} <br>
    Layer IDs: {i} <br>
    Subsets: {sub}
    """.format(s=service, v=version, r=req_type, i=id_list, sub=subsets)

    return HttpResponse(response)

