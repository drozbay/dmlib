@echo off

FOR /F "tokens=1,2 delims==" %%i IN (.\config.txt) DO (
    IF "%%i"=="ANACONDA_ENV_NAME" SET ENVIRONMENT_NAME=%%j
)

IF "%ENVIRONMENT_NAME%"=="" (
    echo Error: Anaconda environment name is not set.
    exit /b 1
)

Powershell.exe -executionpolicy bypass -NoExit -Command ". devwraps\scripts\base.ps1; Activate-Anaconda -environmentName %ENVIRONMENT_NAME%"