"""Utilities for working with files."""


class FileUtil:
    """Class for file utilities."""

    def get_file_extension(self, filename):
        """Gets the file extension."""
        return filename.split(".")[-1]
