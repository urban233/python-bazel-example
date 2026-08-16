# ======================================================================================
# A tiny repository rule that fetches a standalone CPython interpreter and
# exposes its entire tree as `@<repo>//:files`.
#
# Why a custom rule instead of plain http_archive? The python-build-standalone
# LINUX tarballs (release >= 20240224) contain an INFINITE SYMLINK LOOP under
# share/terminfo (an upstream ncurses quirk, see
# https://github.com/astral-sh/python-build-standalone/issues/231). Bazel's
# glob() trips over it -- but only on hosts that are not Linux, which would
# make a plain http_archive produce host-dependent results. The fix (the same
# one rules_python uses internally) is to delete share/terminfo right after
# extraction, before the glob below ever runs. rctx.delete() works on every
# host, so the repository is identical no matter where it is built.
# ======================================================================================

# Injected as the repository's BUILD file. `pkg_files` in //packaging reads the
# resulting `filegroup(name = "files")` and maps its contents into the bundle.
_BUILD_FILE = """\
filegroup(
    name = "files",
    srcs = glob(
        ["**"],
        exclude = [
            "*.pdb",  # debug symbols, not needed at runtime
            "**/*.pdb",
            "BUILD.bazel",  # files Bazel injects into the repo; not part of the runtime
            "WORKSPACE",
            "REPO.bazel",
            "MODULE.bazel",
            "**/__pycache__/**",
            "**/test/**",  # bundled test suites (large, unused at runtime)
            "**/tests/**",
        ],
    ),
    visibility = ["//visibility:public"],
)
"""

def _standalone_python_impl(rctx):
    # Download the tarball and extract it. `strip_prefix = "python"` moves the
    # archive's only top-level directory (python/) to the repo root.
    rctx.download_and_extract(
        url = rctx.attr.url,
        sha256 = rctx.attr.sha256,
        strip_prefix = "python",
    )

    if rctx.attr.delete_terminfo:
        # Remove the share/terminfo symlink loop described at the top of this
        # file. This must happen BEFORE the glob in _BUILD_FILE is evaluated.
        rctx.delete("share/terminfo")

    rctx.file("BUILD.bazel", _BUILD_FILE)

standalone_python = repository_rule(
    implementation = _standalone_python_impl,
    attrs = {
        "url": attr.string(mandatory = True),
        "sha256": attr.string(mandatory = True),
        # True for the Linux builds (which ship the terminfo symlink loop);
        # False for Windows/macOS (which don't).
        "delete_terminfo": attr.bool(default = False),
    },
    doc = "Fetch a standalone CPython interpreter; expose all files as :files",
)
