# Python + Bazel Example

[**Bazel Configuration**](#bazel-configuration) | [**Build and Run**](#build-and-run) | [**Portable Packaging**](#portable-packaging) | [**Requirements**](#requirements)

A minimal template demonstrating how to configure [Bazel](https://bazel.build)
for a Python project using [rules_python](https://github.com/bazel-contrib/rules_python),
Bzlmod, pinned PyPI dependencies, and reproducible cross-platform packaging.

The example application uses NumPy to calculate a sum and a small utility class
to extract a file extension. The packaging target goes further than a normal
Bazel Python binary: it creates a flat, self-contained archive containing the
application, NumPy, and a standalone CPython interpreter.

## Project Structure

```text
.
├── MODULE.bazel                         # Bzlmod dependencies and toolchains
├── MODULE.bazel.lock                    # Locked module resolution
├── .bazelrc                             # Bazel runtime and Windows settings
├── .bazelversion                         # Pinned JetBrains Bazel version
├── BUILD.bazel                           # Root package
├── packaging/
│   ├── BUILD.bazel                       # Cross-platform portable bundle
│   ├── run.bat                           # Windows launcher
│   ├── run.sh                            # macOS/Linux launcher
│   └── standalone_python.bzl             # Standalone CPython repository rule
└── sdk/
    └── python/
        ├── BUILD.bazel                   # Requirements update target
        ├── requirements.in                # Direct Python dependencies
        ├── requirements_lock.txt           # Hash-pinned dependency lock file
        ├── src/
        │   └── python_bazel_example/
        │       ├── BUILD.bazel             # Python library, binary, and wheel
        │       ├── __init__.py
        │       ├── cli.py                  # Application logic
        │       ├── file_util.py            # File utility example
        │       └── main.py                 # Application entry point
        └── tests/
            ├── BUILD.bazel
            └── test_numpy_usage.py
```

## Bazel Configuration

This project uses modern Bazel configuration with Bzlmod.

### `MODULE.bazel`

- Uses Bzlmod for dependency and toolchain management.
- Configures `rules_python` 2.3.1 with CPython 3.11.
- Configures `rules_pkg` 1.0.1 for ZIP creation.
- Resolves NumPy through the hash-pinned `sdk/python/requirements_lock.txt` file.
- Defines standalone CPython and NumPy inputs for Windows, Linux, and macOS.
- Pins every downloaded runtime and wheel with SHA-256 checksums.

### `.bazelrc` and `.bazelversion`

- Enables platform-specific Bazel configuration.
- Enables runfiles and Windows symlink support required by the Python toolchain.
- Uses the Bazel version specified in `.bazelversion` when running through
  [Bazelisk](https://github.com/bazelbuild/bazelisk).
- Uses `C:/bzl` as the Bazel output user root on Windows.

### Python BUILD targets

The application package defines:

- `//sdk/python/src/python_bazel_example:lib` - reusable Python library.
- `//sdk/python/src/python_bazel_example:main` - runnable Bazel Python binary.
- `//sdk/python/src/python_bazel_example:wheel` - Python wheel distribution.
- `//sdk/python/tests:test_numpy_usage` - NumPy usage test.

## Application Overview

The application demonstrates a small Python package with a third-party native
dependency:

- `cli.py` creates a NumPy array and prints its sum.
- `file_util.py` extracts the extension from `demo.txt`.
- `main.py` provides the executable module entry point.

Expected output:

```text
The NumPy sum is 6
The file extension is txt
```

## Build and Run

Run the test suite:

```text
bazel test //sdk/python/...
```

Build the application binary:

```text
bazel build //sdk/python/src/python_bazel_example:main
```

Run the application through Bazel:

```text
bazel run //sdk/python/src/python_bazel_example:main
```

Build the Python wheel:

```text
bazel build //sdk/python/src/python_bazel_example:wheel
```

Update the locked Python requirements after changing `requirements.in`:

```text
bazel run //sdk/python:requirements.update
```

## Portable Packaging

The `//packaging:portable_app` target creates a flat ZIP containing:

- Standalone CPython 3.11.13.
- The `python_bazel_example` application source files.
- NumPy 2.3.2, including its native extension modules and platform libraries.
- An OS-specific launcher: `run.bat` on Windows or `run.sh` on macOS/Linux.

The target does not depend on Python being installed on the destination machine.
The launcher sets the bundle's `app/` directory on `PYTHONPATH` and runs the
bundled interpreter directly.

### Supported Platforms

| Target platform | Bazel platform target | Output archive |
| --- | --- | --- |
| Windows x86_64 | `//packaging:windows_x86_64` | `portable_app_windows_x86_64.zip` |
| Linux x86_64 | `//packaging:linux_x86_64` | `portable_app_linux_x86_64.zip` |
| Linux AArch64 | `//packaging:linux_aarch64` | `portable_app_linux_aarch64.zip` |
| macOS x86_64 | `//packaging:macos_x86_64` | `portable_app_macos_x86_64.zip` |
| macOS arm64 | `//packaging:macos_arm64` | `portable_app_macos_arm64.zip` |

### Build a Bundle

Build for the host platform:

```text
bazel build //packaging:portable_app
```

Build a specific target platform from any supported build host:

```text
bazel build //packaging:portable_app --platforms=//packaging:windows_x86_64
bazel build //packaging:portable_app --platforms=//packaging:linux_x86_64
bazel build //packaging:portable_app --platforms=//packaging:linux_aarch64
bazel build //packaging:portable_app --platforms=//packaging:macos_x86_64
bazel build //packaging:portable_app --platforms=//packaging:macos_arm64
```

The named archive is written under `bazel-bin/packaging/`. Bazel also exposes
the declared `portable_app.zip` output as a convenience link to the
platform-specific archive.

### Run a Bundle

On Windows, extract the archive and run:

```text
run.bat
```

On macOS or Linux, extract the archive and run:

```text
./run.sh
```

If the extraction tool does not preserve executable permissions, run
`chmod +x run.sh` first.

The flat layout avoids the deeply nested Bazel runfiles paths that can cause
Windows `MAX_PATH` problems. The archive contains only the runtime layout
needed by the application rather than Bazel's complete runfiles tree.

### Packaging Implementation

- `packaging/BUILD.bazel` defines the target platforms, platform selections,
  file mappings, launcher, and ZIP rule.
- `packaging/run.bat` launches `python\python.exe` with the bundled `app/`
  directory on `PYTHONPATH`.
- `packaging/run.sh` launches `python/bin/python3` and forwards command-line
  arguments.
- `packaging/standalone_python.bzl` removes the upstream Linux `share/terminfo`
  symlink loop before Bazel scans the standalone interpreter tree.
- `rules_pkg` preserves the executable mode for `run.sh` and assembles the
  final archive.

## Requirements

- Bazel 9.x, or [Bazelisk](https://github.com/bazelbuild/bazelisk) using the
  version in `.bazelversion`.
- Internet access on the first build to download Bazel modules, standalone
  Python runtimes, and NumPy wheels.
- For normal development, Python does not need to be installed separately;
  `rules_python` provides the configured interpreter.
- A target machine must match the archive's operating system and architecture.

## Windows-specific Information

- Use Bazelisk to automatically select the version in `.bazelversion`.
- The repository enables Windows symlinks and runfiles in `.bazelrc` for
  `rules_python`.
- The Windows portable archive uses `run.bat` and the `python.exe` standalone
  layout. It does not use the Unix `run.sh` launcher.
- Linux and macOS archives must be built with the matching `--platforms` target
  when cross-building from Windows.

## CI/CD and Release Packaging

The packaging target is suitable for CI jobs because the target platform is
explicit and all runtime downloads are checksum-pinned. A release pipeline can
build each archive independently and publish the five files from
`bazel-bin/packaging/`:

```text
bazel build //packaging:portable_app --platforms=//packaging:windows_x86_64
bazel build //packaging:portable_app --platforms=//packaging:linux_x86_64
bazel build //packaging:portable_app --platforms=//packaging:linux_aarch64
bazel build //packaging:portable_app --platforms=//packaging:macos_x86_64
bazel build //packaging:portable_app --platforms=//packaging:macos_arm64
```

For production releases, test each archive on its target operating system and
architecture before publishing it. Cross-building verifies assembly and target
inputs, but it does not replace runtime testing on every target platform.

## References

- [Bazel Documentation](https://bazel.build/docs)
- [Bazelisk](https://github.com/bazelbuild/bazelisk)
- [Bzlmod Documentation](https://bazel.build/external/module)
- [rules_python](https://github.com/bazel-contrib/rules_python)
- [rules_pkg](https://github.com/bazelbuild/rules_pkg)
- [python-build-standalone](https://github.com/astral-sh/python-build-standalone)
- [NumPy](https://numpy.org/)

## License

Licensed under the BSD 3-Clause License. See [LICENSE](LICENSE) for the full
license text.
