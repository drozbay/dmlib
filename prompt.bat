@echo off
setlocal enabledelayedexpansion

:: Find the Conda installation directory
for /d %%i in ("%~dp0*conda") do (
    if exist "%%i\Scripts\activate.bat" (
        set INSTALL_DIR=%%i
        goto :found_conda
    )
)
echo Error: Could not find Conda installation directory.
echo Please run install_dmlib.bat first.
pause
exit /b 1

:found_conda
:: Read the environment name from environment.yml
for /f "tokens=2 delims=: " %%a in ('findstr /B "name:" "%~dp0environment.yml"') do set ENV_NAME=%%a
if "%ENV_NAME%"=="" (
    echo Error: Could not find environment name in environment.yml
    pause
    exit /b 1
)

:: Set up environment variables for isolation
set CONDA_ENVS_PATH=%INSTALL_DIR%\envs
set CONDA_PKGS_DIRS=%INSTALL_DIR%\pkgs
set CONDA_AUTO_UPDATE_CONDA=false
set PYTHONNOUSERSITE=1

:: Activate the Conda environment
call "%INSTALL_DIR%\Scripts\activate.bat" %ENV_NAME%
if %errorlevel% neq 0 (
    echo Error: Failed to activate the Conda environment.
    pause
    exit /b 1
)

echo Conda environment '%ENV_NAME%' is now active.
echo You may now run Python commands. Eg. 'python .\dmlib\gui.py'

:: Start a new command prompt
cmd /k