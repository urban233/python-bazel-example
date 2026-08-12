import numpy as np

from python_bazel_example.file_util import FileUtil


def main():
    values = np.array([1, 2, 3])
    print(f"The NumPy sum is {values.sum()}")
    print(f"The file extension is {FileUtil().get_file_extension('demo.txt')}")
