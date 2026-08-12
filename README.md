# python-bazel-example
A simple template for building a nested monorepo Python project with Bazel and
`rules_python`.

The Python package lives under `sdk/python/src`, while tests and dependency
metadata live under `sdk/python`. NumPy is resolved through the hash-pinned
`sdk/python/requirements_lock.txt` file.

## Commands

```text
bazel test //sdk/python/...
bazel run //sdk/python/src/python_bazel_example:main
bazel build //sdk/python/src/python_bazel_example:wheel
bazel run //sdk/python:requirements.update
```
