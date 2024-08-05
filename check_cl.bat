@echo off
setlocal enabledelayedexpansion

echo Checking for Microsoft Visual C++...
where cl >nul 2>nul
if %errorlevel% equ 0 (
    echo Microsoft Visual C++ is already installed.
    exit /b 0
)

echo Microsoft Visual C++ not found.
echo You need to install Microsoft Visual C++ Build Tools to continue.
set /p CONTINUE=Try to download installer for Microsoft Visual C++ Build Tools? (Y/N): 
if /i "%CONTINUE%" neq "Y" (
    exit /b 2
)

echo.
echo Downloading Visual Studio Build Tools installer...
:: Use the smaller, offline installer for Build Tools
set VS_BUILDTOOLS_URL=https://aka.ms/vs/17/release/vs_buildtools.exe
set VS_BUILDTOOLS_EXE=%~dp0vs_buildtools.exe

powershell -Command "& {Invoke-WebRequest -Uri '%VS_BUILDTOOLS_URL%' -OutFile '%VS_BUILDTOOLS_EXE%'}"
if %errorlevel% neq 0 (
    echo Error: Failed to download Visual Studio Build Tools installer.
    exit /b 2
)

echo.
echo Download complete.
set /p RUN_INSTALLER=Do you want to run the Visual Studio Build Tools installer now? (Y/N):
if /i "%RUN_INSTALLER%" equ "Y" (
    echo Running the installer. Please select the "Desktop development with C++" workload during installation.
    echo.
    start %VS_BUILDTOOLS_EXE% --norestart --nocache --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended
    echo.
    echo The installer has been started. Please complete the installation manually.
)

exit /b 2
