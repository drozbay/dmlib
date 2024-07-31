@echo off
setlocal enabledelayedexpansion

:: Set up variables
set MINICONDA_INSTALLER=Miniconda3-latest-Windows-x86_64.exe
set INSTALL_DIR=%~dp0dmlib_portable
set ENV_NAME=dmlib_env

:: Check if Portable Miniconda is already installed
if not exist "%INSTALL_DIR%\Scripts\conda.exe" (
    echo Portable Miniconda not found. Downloading and installing...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe', '%MINICONDA_INSTALLER%')"
    start /wait "" %MINICONDA_INSTALLER% /InstallationType=JustMe /RegisterPython=0 /S /D=%INSTALL_DIR%
    del %MINICONDA_INSTALLER%
) else (
    echo Portable Miniconda installation found.
)

:: Initialize Conda
call %INSTALL_DIR%\Scripts\activate.bat

:: Check if Conda environment already exists
if not exist %INSTALL_DIR%\envs\%ENV_NAME% (
    :: Create Conda environment
    echo Creating Conda environment...
    call %INSTALL_DIR%\Scripts\conda.exe env create -f environment.yml
    if %errorlevel% neq 0 (
        echo Error: Failed to create Conda environment.
        echo Please check the environment.yml file and ensure all packages are compatible.
        exit /b 1
    )
) else (
    echo Conda environment already exists: %ENV_NAME%
)

:: Set the full path to the Python interpreter in the new environment
set PYTHON_EXE=%INSTALL_DIR%\envs\%ENV_NAME%\python.exe

:: Ensure Cython is installed
%PYTHON_EXE% -m pip install cython

:: Install devwraps
echo Installing devwraps...
cd devwraps
call install_devwraps.bat "%PYTHON_EXE%"
if %errorlevel% neq 0 (
    echo Error: devwraps installation failed.
    exit /b 1
)
cd ..

:: Install zernike
echo Installing zernike...
cd zernike
%PYTHON_EXE% -m pip install -e .
if %errorlevel% neq 0 (
    echo Error: zernike installation failed.
    exit /b 1
)
cd ..

:: Compile Cython extensions for dmlib (if necessary)
echo Compiling Cython extensions for dmlib...
%PYTHON_EXE% setup.py build_ext --inplace
if %errorlevel% neq 0 (
    echo Error: Cython compilation for dmlib failed.
    exit /b 1
)

:: Install dmlib
echo Installing dmlib...
%PYTHON_EXE% -m pip install -e .
if %errorlevel% neq 0 (
    echo Error: dmlib installation failed.
    exit /b 1
)

:: Verify installation
echo Verifying installation...
%PYTHON_EXE% -c "import dmlib, devwraps, zernike; print('All modules installed successfully')"

echo Installation complete! You can now use dmlib.