@echo off
setlocal enabledelayedexpansion

:: Set up variables
set MINICONDA_INSTALLER=Miniconda3-latest-Windows-x86_64.exe
set INSTALL_DIR=%~dp0conda

:: Check for Visual C++
call check_cl.bat
set VC_CHECK_RESULT=%errorlevel%
if %VC_CHECK_RESULT% equ 2 (
    echo Run this script again after installing Build Tools for Visual Studio (2019 or later^)
    goto exit_error
) else if %VC_CHECK_RESULT% neq 0 (
    echo An unexpected error occurred during Visual C++ check. Exiting...
    goto exit_error
)

:: Read the environment name from environment.yml
for /f "tokens=2 delims=: " %%a in ('findstr /B "name:" environment.yml') do set ENV_NAME=%%a
if "%ENV_NAME%"=="" (
    echo Error: Could not find environment name in environment.yml
    goto exit_error
)
echo Conda environment name: %ENV_NAME%

:: Set up temp folder
set CUSTOM_TEMP=%~dp0temp
if not exist "%CUSTOM_TEMP%" mkdir "%CUSTOM_TEMP%"
set TEMP=%CUSTOM_TEMP%
set TMP=%CUSTOM_TEMP%

:: Check if Portable Miniconda is already installed
if not exist "%INSTALL_DIR%\Scripts\conda.exe" (
    echo Portable Miniconda not found. Downloading and installing...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe', '%MINICONDA_INSTALLER%')"
    start /wait "" %MINICONDA_INSTALLER% /InstallationType=JustMe /RegisterPython=0 /S /NoRegistry=1 /D=%INSTALL_DIR%
    del %MINICONDA_INSTALLER%
    :: Confirm that the installation was successful
    if not exist "%INSTALL_DIR%\Scripts\conda.exe" (
        echo Error: Miniconda installation failed.
        goto exit_error
    )
) else (
    echo Portable Miniconda installation found.
)

:: Set up environment variables for isolation
set CONDA_ENVS_PATH=%INSTALL_DIR%\envs
set CONDA_PKGS_DIRS=%INSTALL_DIR%\pkgs
set CONDA_AUTO_UPDATE_CONDA=false
set PYTHONNOUSERSITE=1

:: Activate the base environment
call %INSTALL_DIR%\Scripts\activate.bat

:: Check if Conda environment already exists
if not exist %INSTALL_DIR%\envs\%ENV_NAME% (
    :: Create Conda environment
    echo Creating Conda environment...
    %INSTALL_DIR%\Scripts\conda.exe env create -f environment.yml
    if %errorlevel% neq 0 (
        echo Error: Failed to create Conda environment.
        echo Please check the environment.yml file and ensure all packages are compatible.
        goto exit_error
    )
) else (
    echo Conda environment already exists: %ENV_NAME%
)

:: Activate the environment
call %INSTALL_DIR%\Scripts\activate.bat %ENV_NAME%

:: Verify active environment
for /f "tokens=2 delims=:" %%a in ('call %INSTALL_DIR%\Scripts\conda.exe info ^| findstr /C:"active environment"') do set ACTIVE_ENV=%%a
set ACTIVE_ENV=%ACTIVE_ENV:)=%
set ACTIVE_ENV=%ACTIVE_ENV: =%
echo Active environment: %ACTIVE_ENV%
if not "%ACTIVE_ENV%"=="%ENV_NAME%" (
    echo Error: Failed to activate Conda environment: %ENV_NAME%
    goto exit_error
)

:: Print the path of the python executable
echo Full path to Python interpreter (CONDA_PREFIX): %CONDA_PREFIX%\python.exe

:: Install devwraps
echo Installing devwraps...
cd devwraps
call install_devwraps.bat
if %errorlevel% neq 0 (
    echo Error: devwraps installation failed.
    goto exit_error
)
cd ..

:: Install zernike
echo Installing zernike...
cd zernike
del /q dist\*.whl
call %CONDA_PREFIX%\python.exe setup.py bdist_wheel
if %errorlevel% neq 0 (
    echo Error: Failed to build devwraps wheel.
    goto exit_error
)
echo zernike wheel built successfully.
for %%f in (dist\*.whl) do (
    set WHEEL_FILE=%%f
)
if not defined WHEEL_FILE (
    echo Error: zernike wheel file not found.
    goto exit_error
)
call %CONDA_PREFIX%\Scripts\pip.exe install %WHEEL_FILE%
if %errorlevel% neq 0 (
    echo Error: zernike installation failed.
    goto exit_error
)
echo zernike installed successfully.
cd ..

:: Install dmlib
echo Installing dmlib...
del /q dist\*.whl
call %CONDA_PREFIX%\python.exe setup.py bdist_wheel
if %errorlevel% neq 0 (
    echo Error: Failed to build dmlib wheel.
    goto exit_error
)
echo dmlib wheel built successfully.
for %%f in (dist\*.whl) do (
    set WHEEL_FILE=%%f
)
if not defined WHEEL_FILE (
    echo Error: dmlib wheel file not found.
    goto exit_error
)
call %CONDA_PREFIX%\Scripts\pip.exe install %WHEEL_FILE%
if %errorlevel% neq 0 (
    echo Error: dmlib installation failed.
    goto exit_error
)
echo dmlib installed successfully.

:: Verify installation
echo Verifying dmlib installation...
call %CONDA_PREFIX%\python.exe -c "import dmlib, devwraps, zernike; print('All modules installed successfully')"
if %errorlevel% neq 0 (
    echo Error: dmlib installation verification failed.
    goto exit_error
)
echo Installation complete! You can now use dmlib.
echo To activate this environment in the future, run:
echo call %INSTALL_DIR%\Scripts\activate.bat %ENV_NAME%
goto exit_success

:exit_error
echo Press any key to exit...
pause >nul
exit /b 1

:exit_success
if %CUSTOM_TEMP% == %TEMP% rmdir /s /q %CUSTOM_TEMP%
echo Press any key to exit...
pause >nul
exit /b 0