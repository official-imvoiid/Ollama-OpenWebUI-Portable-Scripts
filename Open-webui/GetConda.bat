@echo off
setlocal EnableDelayedExpansion
cd /D "%~dp0"
set SCRIPT_DIR=%CD%
set INSTALL_DIR=%SCRIPT_DIR%\installer_files
set CONDA_ROOT_PREFIX=%INSTALL_DIR%\Miniconda
set ENV_DIR=%SCRIPT_DIR%\installer_files\Environments
set CONDARC=%CONDA_ROOT_PREFIX%\.condarc
set MINICONDA_DOWNLOAD_URL=https://repo.anaconda.com/miniconda/Miniconda3-py310_23.11.0-2-Windows-x86_64.exe

echo Portable Miniconda Setup
echo.

:: Create directories
echo Creating installation directories...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%ENV_DIR%" mkdir "%ENV_DIR%"

echo.
echo Downloading Miniconda installer...
echo URL: %MINICONDA_DOWNLOAD_URL%

:: Download using curl
echo Downloading with CURL...
curl -L "%MINICONDA_DOWNLOAD_URL%" -o "%INSTALL_DIR%\miniconda_installer.exe"

if not exist "%INSTALL_DIR%\miniconda_installer.exe" (
    echo CURL download failed, trying certutil...
    echo %MINICONDA_DOWNLOAD_URL% > "%INSTALL_DIR%\download_url.txt"
    certutil -urlcache -split -f @"%INSTALL_DIR%\download_url.txt" "%INSTALL_DIR%\miniconda_installer.exe"
    del "%INSTALL_DIR%\download_url.txt"
)

if not exist "%INSTALL_DIR%\miniconda_installer.exe" (
    echo All download methods failed.
    echo.
    echo Please download the installer manually from:
    echo %MINICONDA_DOWNLOAD_URL%
    echo.
    echo Then place it in: %INSTALL_DIR%\miniconda_installer.exe
    pause
    goto end
)

echo Downloaded file size:
for %%A in ("%INSTALL_DIR%\miniconda_installer.exe") do echo %%~zA bytes

echo.
echo Installing Miniconda...
start /wait "" "%INSTALL_DIR%\miniconda_installer.exe" /InstallationType=JustMe /NoShortcuts=1 /AddToPath=0 /RegisterPython=0 /NoRegistry=1 /S /D=%CONDA_ROOT_PREFIX%

if not exist "%CONDA_ROOT_PREFIX%\_conda.exe" (
    echo.
    echo Miniconda installation failed.
    echo Please check error messages above.
    pause
    goto end
)

del "%INSTALL_DIR%\miniconda_installer.exe"

echo Portable Miniconda Downloaded! Use SetEnv.bat file now.

:end
pause