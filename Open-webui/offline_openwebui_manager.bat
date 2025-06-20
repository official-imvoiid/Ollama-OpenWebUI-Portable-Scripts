@echo off
setlocal enabledelayedexpansion

:: Get current directory and set paths
set "SCRIPT_DIR=%~dp0"

:: Miniconda paths
set "MINICONDA=%SCRIPT_DIR%installer_files\Miniconda"
set "SCRIPTS=%SCRIPT_DIR%installer_files\Miniconda\Scripts"
set "BIN=%SCRIPT_DIR%installer_files\Miniconda\Library\bin"
set "CONDA=%SCRIPT_DIR%installer_files\Miniconda\_CONDA.exe"

:: Environment paths
set "ENV_DIR=%SCRIPT_DIR%installer_files\Environments\open-webui"
set "PYTHON_EXE=%ENV_DIR%\python.exe"

:: Temporary environment for downloading
set "TEMP_ENV=%SCRIPT_DIR%installer_files\Environments\GetOpenWebui"

:: OpenWebUI Wheel folder (right where script is located)
set "OPENWEBUI_WHEEL=%SCRIPT_DIR%OpenWebuiWheel"

:: Check if Miniconda exists
if not exist "%MINICONDA%" (
    echo Error: Miniconda directory not found at %MINICONDA%
    pause
    exit /b 1
)

:: Set PATH
set "PATH=%ENV_DIR%;%ENV_DIR%\Scripts;%ENV_DIR%\Library\bin;%MINICONDA%;%MINICONDA%\condabin;%SCRIPTS%;%BIN%;%PATH%"

:main_menu
cls
echo ============================================
echo      Open-WebUI Management Script
echo ============================================
echo.
echo Please select an option:
echo 1. Download Open-WebUI wheels to OpenWebuiWheel folder
echo 2. Create new env 'open-webui' and install from wheels
echo 3. Delete and recreate environment
echo 4. Update wheels in OpenWebuiWheel folder
echo 5. Reinstall packages from OpenWebuiWheel (keep env)
echo 6. Exit
echo.
set /p choice="Enter your choice (1-6): "

if "%choice%"=="1" goto download_to_folder
if "%choice%"=="2" goto create_and_install
if "%choice%"=="3" goto delete_recreate
if "%choice%"=="4" goto update_wheels
if "%choice%"=="5" goto reinstall_packages
if "%choice%"=="6" goto exit_script
echo.
echo Invalid choice. Please enter 1, 2, 3, 4, 5, or 6.
echo.
pause
goto main_menu

:download_to_folder
echo.
echo ============================================
echo    Downloading to OpenWebuiWheel Folder
echo ============================================
echo.

:: Create OpenWebuiWheel directory
if not exist "%OPENWEBUI_WHEEL%" (
    echo Creating OpenWebuiWheel directory...
    mkdir "%OPENWEBUI_WHEEL%"
)

:: Clean existing files
echo Cleaning existing package files...
if exist "%OPENWEBUI_WHEEL%\*.*" (
    del /q "%OPENWEBUI_WHEEL%\*.*" 2>nul
)

:: Clean any existing temp environment
if exist "%TEMP_ENV%" (
    echo Cleaning previous temporary environment...
    call :safe_delete "%TEMP_ENV%"
)

echo Creating temporary environment 'GetOpenWebui'...
call "%MINICONDA%\Scripts\conda.exe" create -p "%TEMP_ENV%" python=3.11 pip wheel setuptools -y

if !errorlevel! neq 0 (
    echo Error: Failed to create temporary environment
    echo.
    pause
    goto main_menu
)

echo Temporary environment created successfully.
echo.
echo Downloading all open-webui dependencies...

:: Create temp download directory
set "TEMP_DOWNLOAD=%TEMP_ENV%\temp_download"
if not exist "%TEMP_DOWNLOAD%" mkdir "%TEMP_DOWNLOAD%"

:: Download packages
"%TEMP_ENV%\python.exe" -m pip download open-webui wheel setuptools pip --dest "%TEMP_DOWNLOAD%"

if !errorlevel! neq 0 (
    echo Error: Failed to download packages
    call :cleanup_and_return
)

:: Check if download directory has files
dir /b "%TEMP_DOWNLOAD%\*.*" >nul 2>&1
if !errorlevel! neq 0 (
    echo Error: No files were downloaded
    call :cleanup_and_return
)

echo Moving packages to OpenWebuiWheel folder...

:: Copy files using xcopy (more reliable than robocopy for this use case)
xcopy "%TEMP_DOWNLOAD%\*.*" "%OPENWEBUI_WHEEL%\" /Y /Q
if !errorlevel! neq 0 (
    echo Error: Failed to copy files to OpenWebuiWheel folder
    call :cleanup_and_return
)

:: Count files to verify success
set file_count=0
for %%f in ("%OPENWEBUI_WHEEL%\*.*") do set /a file_count+=1

if !file_count! gtr 0 (
    echo.
    echo ============================================
    echo   Download completed successfully!
    echo ============================================
    echo.
    echo All packages saved to: %OPENWEBUI_WHEEL%
    echo Total files downloaded: !file_count!
    echo.
    echo Required packages included:
    echo - open-webui and all dependencies
    echo - wheel package (for building^)
    echo - setuptools package
    echo - pip package
    echo.
    echo  You can now use option 2 to install from these packages.
) else (
    echo Error: No files were successfully copied to OpenWebuiWheel folder
)

call :cleanup_temp_env
echo.
echo Download process completed.
echo.
pause
goto main_menu

:create_and_install
echo.
echo ============================================
echo    Create Environment and Install
echo ============================================

:: Check if OpenWebuiWheel folder exists and has files
if not exist "%OPENWEBUI_WHEEL%" (
    echo Error: OpenWebuiWheel folder not found at %OPENWEBUI_WHEEL%
    echo Please run option 1 first to download packages.
    echo.
    pause
    goto main_menu
)

dir /b "%OPENWEBUI_WHEEL%\*.*" >nul 2>&1
if !errorlevel! neq 0 (
    echo Error: No package files found in %OPENWEBUI_WHEEL%
    echo Please run option 1 first to download packages.
    echo.
    pause
    goto main_menu
)

:: Check if environment already exists
if exist "%ENV_DIR%" (
    echo Environment 'open-webui' already exists.
    set /p overwrite="Delete existing environment? (Y/N): "
    if /i "!overwrite!"=="Y" (
        echo Deleting existing environment...
        call :safe_delete "%ENV_DIR%"
        if exist "%ENV_DIR%" (
            echo Error: Could not delete existing environment.
            echo Please close any applications using it and try again.
            echo.
            pause
            goto main_menu
        )
        echo Existing environment deleted.
    ) else (
        echo Installation cancelled.
        echo.
        pause
        goto main_menu
    )
)

echo Creating conda environment 'open-webui' with Python 3.11...
call "%MINICONDA%\Scripts\conda.exe" create -p "%ENV_DIR%" python=3.11 -y

if !errorlevel! neq 0 (
    echo Error: Failed to create environment
    echo.
    pause
    goto main_menu
)

echo Environment created successfully.
echo.
echo Installing basic tools first...
"%PYTHON_EXE%" -m pip install --no-index --find-links "%OPENWEBUI_WHEEL%" pip wheel setuptools

if !errorlevel! neq 0 (
    echo Error: Failed to install basic tools
    echo.
    pause
    goto main_menu
)

echo Installing open-webui from local packages...
echo (This works exactly like: pip install open-webui)
echo.
"%PYTHON_EXE%" -m pip install --no-index --find-links "%OPENWEBUI_WHEEL%" open-webui

if !errorlevel! equ 0 (
    echo.
    echo ============================================
    echo   Installation completed successfully!
    echo ============================================
    echo.
    echo  Open-WebUI installed from local packages.
    echo  Works exactly like 'pip install open-webui' but offline!
    echo.
    echo You can now run your launch script to start Open-WebUI.
) else (
    echo.
    echo ============================================
    echo       Installation failed!
    echo ============================================
    echo.
    echo Troubleshooting steps:
    echo 1. Try option 4 to update packages
    echo 2. Check if all required packages are in OpenWebuiWheel folder
    echo 3. Try option 3 to delete and recreate environment
)

echo.
pause
goto main_menu

:delete_recreate
echo.
echo ============================================
echo    Delete and Recreate Environment
echo ============================================

:: Check if OpenWebuiWheel folder exists
if not exist "%OPENWEBUI_WHEEL%" (
    echo Error: OpenWebuiWheel folder not found at %OPENWEBUI_WHEEL%
    echo Please run option 1 first to download packages.
    echo.
    pause
    goto main_menu
)

dir /b "%OPENWEBUI_WHEEL%\*.*" >nul 2>&1
if !errorlevel! neq 0 (
    echo Error: No package files found in OpenWebuiWheel folder.
    echo Please run option 1 first to download packages.
    echo.
    pause
    goto main_menu
)

:: Check if environment exists
if not exist "%ENV_DIR%" (
    echo Environment 'open-webui' does not exist.
    echo Use option 2 to create new environment.
    echo.
    pause
    goto main_menu
)

echo This will DELETE the current environment and create a fresh one.
set /p confirm="Are you sure? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Operation cancelled.
    echo.
    pause
    goto main_menu
)

echo Deleting existing environment...
call :safe_delete "%ENV_DIR%"

if exist "%ENV_DIR%" (
    echo Error: Failed to delete environment completely.
    echo Close any applications using this environment and try again.
    echo.
    pause
    goto main_menu
)

echo Creating new conda environment 'open-webui' with Python 3.11...
call "%MINICONDA%\Scripts\conda.exe" create -p "%ENV_DIR%" python=3.11 -y

if !errorlevel! neq 0 (
    echo Error: Failed to create environment
    echo.
    pause
    goto main_menu
)

echo Installing basic tools first...
"%PYTHON_EXE%" -m pip install --no-index --find-links "%OPENWEBUI_WHEEL%" pip wheel setuptools

if !errorlevel! neq 0 (
    echo Warning: Failed to install basic tools, continuing...
)

echo Installing open-webui from local packages...
"%PYTHON_EXE%" -m pip install --no-index --find-links "%OPENWEBUI_WHEEL%" open-webui

if !errorlevel! equ 0 (
    echo.
    echo ============================================
    echo   Environment recreated successfully!
    echo ============================================
    echo.
    echo Fresh installation completed from local packages!
) else (
    echo.
    echo ============================================
    echo       Recreation failed!
    echo ============================================
    echo.
    echo Please try option 4 to update packages or check the package files.
)

echo.
pause
goto main_menu

:update_wheels
echo.
echo ============================================
echo    Update Packages in OpenWebuiWheel Folder
echo ============================================
echo.
echo This will download the latest open-webui packages and update
echo the OpenWebuiWheel folder.
echo.

:: Create OpenWebuiWheel directory if it doesn't exist
if not exist "%OPENWEBUI_WHEEL%" (
    echo Creating OpenWebuiWheel directory...
    mkdir "%OPENWEBUI_WHEEL%"
)

echo Clearing old packages...
if exist "%OPENWEBUI_WHEEL%\*.*" (
    del /q "%OPENWEBUI_WHEEL%\*.*" 2>nul
)

:: Clean any existing temp environment
if exist "%TEMP_ENV%" (
    echo Cleaning previous temporary environment...
    call :safe_delete "%TEMP_ENV%"
)

echo Creating temporary environment 'GetOpenWebui'...
call "%MINICONDA%\Scripts\conda.exe" create -p "%TEMP_ENV%" python=3.11 pip wheel setuptools -y

if !errorlevel! neq 0 (
    echo Error: Failed to create temporary environment
    echo.
    pause
    goto main_menu
)

echo Downloading latest open-webui packages...

:: Create temp download directory
set "TEMP_DOWNLOAD=%TEMP_ENV%\temp_download"
if not exist "%TEMP_DOWNLOAD%" mkdir "%TEMP_DOWNLOAD%"

"%TEMP_ENV%\python.exe" -m pip download open-webui wheel setuptools pip --dest "%TEMP_DOWNLOAD%"

if !errorlevel! neq 0 (
    echo Error: Failed to download packages
    call :cleanup_and_return
)

echo Moving packages to OpenWebuiWheel folder...
xcopy "%TEMP_DOWNLOAD%\*.*" "%OPENWEBUI_WHEEL%\" /Y /Q

if !errorlevel! neq 0 (
    echo Error: Failed to copy packages to OpenWebuiWheel folder
    call :cleanup_and_return
)

:: Count files to verify success
set file_count=0
for %%f in ("%OPENWEBUI_WHEEL%\*.*") do set /a file_count+=1

if !file_count! gtr 0 (
    echo.
    echo ============================================
    echo   Packages updated successfully!
    echo ============================================
    echo.
    echo Latest packages saved to: %OPENWEBUI_WHEEL%
    echo Total files: !file_count!
    echo.
    echo  Packages updated successfully!
) else (
    echo.
    echo Update failed! No packages were copied to the final location.
)

call :cleanup_temp_env
echo.
pause
goto main_menu

:reinstall_packages
echo.
echo ============================================
echo    Reinstall Packages from OpenWebuiWheel
echo ============================================
echo.
echo This will uninstall and reinstall open-webui packages
echo from local packages without recreating the conda environment.
echo.

:: Check if environment exists
if not exist "%ENV_DIR%" (
    echo Error: Environment 'open-webui' does not exist at %ENV_DIR%
    echo Please run option 2 first to create the environment.
    echo.
    pause
    goto main_menu
)

:: Check if OpenWebuiWheel folder exists
if not exist "%OPENWEBUI_WHEEL%" (
    echo Error: OpenWebuiWheel folder not found at %OPENWEBUI_WHEEL%
    echo Please run option 1 first to download packages.
    echo.
    pause
    goto main_menu
)

dir /b "%OPENWEBUI_WHEEL%\*.*" >nul 2>&1
if !errorlevel! neq 0 (
    echo Error: No package files found in %OPENWEBUI_WHEEL%
    echo Please run option 1 first to download packages.
    echo.
    pause
    goto main_menu
)

:: Check if Python executable exists
if not exist "%PYTHON_EXE%" (
    echo Error: Python executable not found at %PYTHON_EXE%
    echo The environment may be corrupted. Try option 3 to recreate it.
    echo.
    pause
    goto main_menu
)

set /p confirm="This will reinstall open-webui packages. Continue? (Y/N): "
if /i not "%confirm%"=="Y" (
    echo Operation cancelled.
    echo.
    pause
    goto main_menu
)

echo Uninstalling open-webui (keeping compatible dependencies)...
"%PYTHON_EXE%" -m pip uninstall open-webui -y

if !errorlevel! neq 0 (
    echo Warning: Failed to uninstall open-webui (it may not be installed)
    echo Continuing with installation...
)

echo.
echo Upgrading basic tools from local packages...
"%PYTHON_EXE%" -m pip install --no-index --find-links "%OPENWEBUI_WHEEL%" --upgrade pip wheel setuptools

if !errorlevel! neq 0 (
    echo Warning: Failed to upgrade basic tools
    echo Continuing with open-webui installation...
)

echo.
echo Installing open-webui from local packages...
echo (This will upgrade/reinstall all dependencies as needed)
"%PYTHON_EXE%" -m pip install --no-index --find-links "%OPENWEBUI_WHEEL%" --force-reinstall open-webui

if !errorlevel! equ 0 (
    echo.
    echo ============================================
    echo   Reinstallation completed successfully!
    echo ============================================
    echo.
    echo  Open-WebUI has been reinstalled from local packages.
    echo  All packages have been refreshed while keeping the environment intact.
    echo.
    echo You can now run your launch script to start Open-WebUI.
) else (
    echo.
    echo ============================================
    echo       Reinstallation failed!
    echo ============================================
    echo.
    echo Troubleshooting steps:
    echo 1. Try option 4 to update packages
    echo 2. Try option 3 to delete and recreate environment
    echo 3. Check if packages in OpenWebuiWheel folder are complete
)

echo.
pause
goto main_menu

:: Helper function to safely delete directories
:safe_delete
set "target_dir=%~1"
if exist "%target_dir%" (
    rmdir /s /q "%target_dir%" 2>nul
    timeout /t 1 /nobreak >nul 2>&1
    if exist "%target_dir%" (
        rmdir /s /q "%target_dir%" 2>nul
        timeout /t 2 /nobreak >nul 2>&1
    )
)
goto :eof

:: Helper function to cleanup temp environment
:cleanup_temp_env
echo Cleaning up temporary environment...
if exist "%TEMP_ENV%" (
    call :safe_delete "%TEMP_ENV%"
    if exist "%TEMP_ENV%" (
        echo Warning: Temporary environment may still exist at %TEMP_ENV%
    ) else (
        echo Temporary environment cleaned successfully.
    )
)
goto :eof

:: Helper function to cleanup and return to menu
:cleanup_and_return
call :cleanup_temp_env
echo.
pause
goto main_menu

:exit_script
echo.
echo Exiting Open-WebUI Management Script...
exit /b 0