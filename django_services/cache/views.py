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
