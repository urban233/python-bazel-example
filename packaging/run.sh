#!/bin/sh
# Portable app launcher for macOS / Linux.
#
# It sits at the zip root next to the bundled runtime. The bundle layout is:
#
#   <bundle>/python/               standalone CPython 3.11.13
#       bin/python3                   the interpreter (runs from any CWD)
#       lib/python3.11/               stdlib
#   <bundle>/app/                  our package + numpy, made importable below
#   <bundle>/run.sh                this file
#
# The exit code is propagated automatically because of `exec`: this shell is
# REPLACED by the python process, so `./run.sh; echo $?` prints the app's
# real exit status.

# Resolve the directory this script lives in. $0 may be a relative path, and
# the user may run the script from any directory, so we normalize it first:
DIR="$(cd "$(dirname "$0")" && pwd)"

# Make the bundled packages importable regardless of the current directory:
export PYTHONPATH="$DIR/app"

# Run our main module with the bundled interpreter, forwarding arguments.
# -m python_bazel_example.main : run the module as the program (main.py calls cli.main()).
exec "$DIR/python/bin/python3" -m python_bazel_example.main "$@"
