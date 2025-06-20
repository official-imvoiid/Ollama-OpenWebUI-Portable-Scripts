@echo off
setlocal enabledelayedexpansion

:: Get current directory and set paths
set "SCRIPT_DIR=%~dp0"

:: Miniconda paths (matching your Cmd.bat structure)
set "MINICONDA=%SCRIPT_DIR%installer_files\Miniconda"
set "SCRIPTS=%SCRIPT_DIR%installer_files\Miniconda\Scripts"
set "BIN=%SCRIPT_DIR%installer_files\Miniconda\Library\bin"
set "CONDA=%SCRIPT_DIR%installer_files\Miniconda\_CONDA.exe"

:: Environment paths
set "ENV_DIR=%SCRIPT_DIR%installer_files\Environments\open-webui"
set "PYTHON_EXE=%ENV_DIR%\python.exe"

:: Check if Miniconda exists
if not exist "%MINICONDA%" (
    echo Error: Miniconda directory not found at %MINICONDA%
    echo Please install Miniconda first.
    pause
    exit /b 1
)

:: Set PATH (including conda environment first, then miniconda)
set "PATH=%ENV_DIR%;%ENV_DIR%\Scripts;%ENV_DIR%\Library\bin;%MINICONDA%;%MINICONDA%\condabin;%SCRIPTS%;%BIN%;%PATH%"

echo ============================================
echo      Open-WebUI Management Script
echo ============================================
echo.
echo Please select an option:
echo 1. Create new conda environment and install Open-WebUI
echo 2. Update existing Open-WebUI installation
echo 3. Delete and reinstall current environment
echo 4. Exit
echo.
set /p choice="Enter your choice (1-4): "

if "%choice%"=="1" goto install_new
if "%choice%"=="2" goto update_existing
if "%choice%"=="3" goto reinstall_env
if "%choice%"=="4" goto exit_script
echo Invalid choice. Please enter 1, 2, 3, or 4.
pause
goto :eof

:install_new
echo.
echo ============================================
echo    Creating New Conda Environment
echo ============================================

:: Check if environment already exists
if exist "%ENV_DIR%" (
    echo Warning: Environment 'open-webui' already exists at %ENV_DIR%
    set /p overwrite="Do you want to delete it and create a new one? (Y/N): "
    if /i "!overwrite!"=="Y" (
        echo Deleting existing environment...
        rmdir /s /q "%ENV_DIR%"
        if !errorlevel! neq 0 (
            echo Error: Failed to delete existing environment
            pause
            exit /b 1
        )
        echo Existing environment deleted.
    ) else (
        echo Installation cancelled.
        pause
        exit /b 0
    )
)

echo Creating conda environment 'open-webui' with Python...
call "%MINICONDA%\Scripts\conda" create -p "%ENV_DIR%" python=3.11 -y

if %errorlevel% neq 0 (
    echo Error: Failed to create conda environment
    pause
    exit /b 1
)

echo Environment created successfully.
echo.

echo Activating conda environment...
call "%MINICONDA%\Scripts\activate" "%ENV_DIR%"

if %errorlevel% neq 0 (
    echo Error: Failed to activate conda environment
    pause
    exit /b 1
)

echo Installing Open-WebUI...
echo Running: pip install open-webui
"%PYTHON_EXE%" -m pip install open-webui

if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo   Open-WebUI installed successfully!
    echo ============================================
    echo.
    echo Installation completed! You can now run your launch script.
) else (
    echo.
    echo ============================================
    echo       Installation failed!
    echo ============================================
    echo Please check the error messages above.
)
goto end_script

:update_existing
echo.
echo ============================================
echo      Updating Open-WebUI
echo ============================================

:: Check if conda environment exists
if not exist "%ENV_DIR%" (
    echo Error: conda environment 'open-webui' not found
    echo Make sure the environment exists at: %ENV_DIR%
    echo Use option 1 to create a new environment first.
    pause
    exit /b 1
)

echo Activating conda environment 'open-webui'...
call "%MINICONDA%\Scripts\activate" "%ENV_DIR%"

if %errorlevel% neq 0 (
    echo Error: Failed to activate conda environment
    pause
    exit /b 1
)

echo Environment activated successfully.
echo.

echo Updating Open-WebUI...
echo Running: pip install --upgrade open-webui
"%PYTHON_EXE%" -m pip install --upgrade open-webui

if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo     Open-WebUI updated successfully!
    echo ============================================
    echo.
    echo Update completed! You can now run your launch script.
) else (
    echo.
    echo ============================================
    echo         Update failed!
    echo ============================================
    echo.
    echo Troubleshooting steps:
    echo 1. Check your internet connection
    echo 2. Try running: pip install --upgrade --force-reinstall open-webui
    echo 3. Check if the environment is properly activated
    echo 4. Manual command: "%PYTHON_EXE%" -m pip install --upgrade open-webui
)
goto end_script

:reinstall_env
echo.
echo ============================================
echo   Delete and Reinstall Environment
echo ============================================

:: Check if environment exists
if not exist "%ENV_DIR%" (
    echo Warning: Environment 'open-webui' does not exist at %ENV_DIR%
    echo Nothing to delete. Use option 1 to create a new environment.
    pause
    exit /b 0
)

echo This will completely delete the current 'open-webui' environment
echo and create a fresh installation.
echo.
set /p confirm="Are you sure you want to continue? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Operation cancelled.
    pause
    exit /b 0
)

echo Deleting existing environment...
rmdir /s /q "%ENV_DIR%"

if %errorlevel% neq 0 (
    echo Error: Failed to delete existing environment
    echo You may need to close any applications using this environment
    pause
    exit /b 1
)

echo Existing environment deleted successfully.
echo.

echo Creating new conda environment 'open-webui' with Python...
call "%MINICONDA%\Scripts\conda" create -p "%ENV_DIR%" python=3.11 -y

if %errorlevel% neq 0 (
    echo Error: Failed to create conda environment
    pause
    exit /b 1
)

echo Environment created successfully.
echo.

echo Activating conda environment...
call "%MINICONDA%\Scripts\activate" "%ENV_DIR%"

if %errorlevel% neq 0 (
    echo Error: Failed to activate conda environment
    pause
    exit /b 1
)

echo Installing Open-WebUI...
echo Running: pip install open-webui
"%PYTHON_EXE%" -m pip install open-webui

if %errorlevel% equ 0 (
    echo.
    echo ============================================
    echo Environment reinstalled successfully!
    echo ============================================
    echo.
    echo Fresh installation completed! You can now run your launch script.
) else (
    echo.
    echo ============================================
    echo     Reinstallation failed!
    echo ============================================
    echo Please check the error messages above.
)
goto end_script

:exit_script
echo Exiting...
exit /b 0

:end_script
:: Optional: Clean up pip cache
echo.
set /p cleanup="Do you want to clean pip cache to free up space? (Y/N): "
if /i "%cleanup%"=="Y" (
    echo Cleaning pip cache...
    "%PYTHON_EXE%" -m pip cache purge
    echo Pip cache cleaned.
)

echo.
pause