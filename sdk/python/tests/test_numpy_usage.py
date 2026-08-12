import unittest

import numpy as np


class NumpyUsageTest(unittest.TestCase):
    def test_numpy_sum(self):
        values = np.array([1, 2, 3])
        self.assertEqual(values.sum(), 6)
