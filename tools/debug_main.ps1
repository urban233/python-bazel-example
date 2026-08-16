# Runs the Bazel py_binary target //sdk/python/src/python_bazel_example:main
# under the PyCharm debugger via RULES_PYTHON_ADDITIONAL_INTERPRETER_ARGS.
#
# Prerequisites:
#   1. In PyCharm: Run > Attach to Process... > Python Debug Server, set host/port
#      (e.g. 127.0.0.1:5678) and press OK. The "Waiting for connection" state is fine.
#   2. Run this script with the matching port:
#        powershell -File tools/debug_main.ps1 -Port 5678
#   3. Breakpoints in sdk/python/src/python_bazel_example/*.py will be hit.
#
# Optional: -PydevdPath to override the pydevd.py location.

param(
    [int]$Port = 5678,
    [string]$DebugHost = "127.0.0.1",
    [string]$PydevdPath = ""
)

$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $RepoRoot

if (-not $PydevdPath) {
    $candidates = @(
        "$env:LOCALAPPDATA\Programs\PyCharm Professional\plugins\python-ce\helpers\pydev\pydevd.py",
        "$env:LOCALAPPDATA\Programs\PyCharm Community\plugins\python-ce\helpers\pydev\pydevd.py",
        "$env:LOCALAPPDATA\Programs\PyCharm\plugins\python-ce\helpers\pydev\pydevd.py"
    )
    $PydevdPath = $candidates | Where-Object { Test-Path $_ } | Select-Object -First 1
}

if (-not $PydevdPath -or -not (Test-Path $PydevdPath)) {
    Write-Error "pydevd.py not found. Pass -PydevdPath explicitly."
}

$fwdPath = $PydevdPath.Replace("\", "/")
$env:RULES_PYTHON_ADDITIONAL_INTERPRETER_ARGS = '"' + $fwdPath + '" --multiprocess --client ' + $DebugHost + ' --port ' + $Port + ' --file'

Write-Host "Attaching via pydevd to $DebugHost`:$Port"
Write-Host "Interpreter args: $env:RULES_PYTHON_ADDITIONAL_INTERPRETER_ARGS"

& bazel run "@//sdk/python/src/python_bazel_example:main"
