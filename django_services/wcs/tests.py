import re

from django.test import TestCase

from .views import SUBSET_PATTERN


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

    def test_proper_errors_returned(self):
        """
        Malformed or invalid WCS requests are rejected with proper error codes.
        """
