@echo off
rem ==================================================================================
rem Launcher for the portable python-bazel-example application.
rem
rem Everything is resolved relative to this script's own location (%~dp0), so the
rem whole folder can be copied to any Windows x86_64 machine and run as-is -- no
rem Python installation required.
rem
rem   DIR          = directory containing run.bat (with trailing backslash)
rem   PYTHONPATH   = tells the interpreter where to find app/ on the import path
rem   -m python_bazel_example.main
rem                = run the module as the program (main.py calls cli.main()).
rem                  We cannot run `cli` directly because cli.py has no
rem                  `if __name__ == "__main__":` block.
rem ==================================================================================
setlocal

set "DIR=%~dp0"
set "PYTHONPATH=%DIR%app"

"%DIR%python\python.exe" -m python_bazel_example.main %*

set "EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %EXIT_CODE%
