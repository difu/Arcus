from os import path
from mimetypes import MimeTypes

from django.http import HttpResponse, Http404


def index(request):
    return HttpResponse("Hello DWD, welcome to my index.")


def cache(request, filename):
    """
    Return the content of a file if it's in the ~/Downloads folder.

    Later, pseudocode::

        if not request.well_formed:
            raise MalformedRequestError
        try:
            ret = get_url_for(request)
        except RequestNotCached:
            get_from_archive(request)  # Raises NotFoundInArchiveError
            cache(request)
        return ret
    """
    filename = path.expanduser("~/Downloads/{}".format(filename))
    if not path.exists(filename):
        raise Http404("File does not exist.")
    with open(filename) as found_file:
        return HttpResponse(found_file.read(),
                            content_type=MimeTypes().guess_type(filename))

