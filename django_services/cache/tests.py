from os import path
import re

from django.test import TestCase
from django.urls import reverse

from .views import STAGING_AREA, SUBSET_PATTERN

class CachingTestCase(TestCase):

    """Conceptual tests, these will not work yet."""

    def test_nonexistent_file_requested(self):
        """If the user wants a nonexistent file, a 404 should be returned."""
        self.assertEqual(
            self.client.get(
                reverse("cache:cache", args=["spam"]).status_code).status_code,
            404)

    def test_file_is_staged_on_request(self):
        """
        If a user wants a file that's not stage, it is staged and returned.
        """
        #: Some valid resource
        filename = path.join(STAGING_AREA, "spam")
        self.assertTrue(not path.exists(filename))
        result = self.client.get(reverse("cache:cache", args=[filename]))
        with open(filename) as open_file:
            self.assertEqual(open_file.read(), result.content)


class WCSParsing(TestCase):

    """WCS queries can be parsed correctly."""

    def test_subset_validity(self):
        """Subsets can be tested for well-formedness."""
        self.assertIsNone(re.search(SUBSET_PATTERN, "foo", re.VERBOSE))
        self.assertIsNone(re.search(SUBSET_PATTERN, "a(10,)", re.VERBOSE))
        self.assertIsNone(re.search(SUBSET_PATTERN, "x(10,)", re.VERBOSE))
        self.assertIsNone(re.search(SUBSET_PATTERN, "x(10, *)", re.VERBOSE))
        self.assertIsNone(re.search(SUBSET_PATTERN, "x(bar)", re.VERBOSE))
        self.assertIsNone(re.search(SUBSET_PATTERN, "y(*)", re.VERBOSE))

        self.assertIsNotNone(re.search(SUBSET_PATTERN, "x(10,20)", re.VERBOSE))
        self.assertIsNotNone(re.search(SUBSET_PATTERN, "y(*,20)", re.VERBOSE))
        self.assertIsNotNone(re.search(SUBSET_PATTERN,
                                       "t(20170208)", re.VERBOSE))
        self.assertIsNotNone(re.search(SUBSET_PATTERN, "z(42,*)", re.VERBOSE))
