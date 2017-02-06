from os import path

from django.test import TestCase
from django.urls import reverse

from .views import STAGING_AREA

class CachingTestCase(TestCase):

    """Conceptual tests, these will not work yet."""

    def test_nonexistent_file_requested(self):
        """If the user wants a nonexistent file, a 404 should be returned."""
        self.assertEqual(
            self.client.get(
                reverse("cache:cache", args=["spam"]).status_code).status_code,
            404)

    def test_file_is_staged_on_request(self):
        """If auser wants a file that's not stage, it is staged and returned."""
        #: Some valid resource
        filename = path.join(STAGING_AREA, "spam")
        self.assertTrue(not path.exists(filename))
        result = self.client.get(reverse("cache:cache", args=[filename]))
        with open(filename) as open_file:
            self.assertEqual(open_file.read(), result.content)