@echo off
setlocal enabledelayedexpansion

:: Get current directory and set paths
set "SCRIPT_DIR=%~dp0"

:: Ollama paths
set "OLLAMA_DIR=%SCRIPT_DIR%ollama"
set "OLLAMA_EXE=%OLLAMA_DIR%\ollama.exe"
set "MODELS_DIR=%OLLAMA_DIR%\models"

:: Miniconda paths (matching your Cmd.bat structure)
set "MINICONDA=%SCRIPT_DIR%installer_files\Miniconda"
set "SCRIPTS=%SCRIPT_DIR%installer_files\Miniconda\Scripts"
set "BIN=%SCRIPT_DIR%installer_files\Miniconda\Library\bin"

:: Environment and Python paths
set "ENV_DIR=%SCRIPT_DIR%installer_files\Environments\open-webui"
set "PYTHON_EXE=%ENV_DIR%\python.exe"

:: Check if ollama directory exists
if not exist "%OLLAMA_DIR%" (
    echo Error: Ollama directory not found at %OLLAMA_DIR%
    pause
    exit /b 1
)

:: Check if ollama.exe exists
if not exist "%OLLAMA_EXE%" (
    echo Error: ollama.exe not found at %OLLAMA_EXE%
    pause
    exit /b 1
)

:: Check if Miniconda exists
if not exist "%MINICONDA%" (
    echo Error: Miniconda directory not found at %MINICONDA%
    pause
    exit /b 1
)

:: Check if conda environment exists
if not exist "%ENV_DIR%" (
    echo Error: conda environment 'open-webui' not found
    echo Make sure the environment exists at: %ENV_DIR%
    pause
    exit /b 1
)

:: Check if Python executable exists
if not exist "%PYTHON_EXE%" (
    echo Error: Python executable not found at %PYTHON_EXE%
    pause
    exit /b 1
)

:: Create models directory if it doesn't exist
if not exist "%MODELS_DIR%" mkdir "%MODELS_DIR%"

:: Set environment variables
set "OLLAMA_MODELS=%MODELS_DIR%"

:: Set PATH (including conda environment first, then miniconda, then ollama)
set "PATH=%ENV_DIR%;%ENV_DIR%\Scripts;%ENV_DIR%\Library\bin;%MINICONDA%;%MINICONDA%\condabin;%SCRIPTS%;%BIN%;%OLLAMA_DIR%;%PATH%"

:: Change to ollama directory for server startup
cd /d "%OLLAMA_DIR%"

echo OLLAMA + OPENWEBUI SERVER 
echo Note: Open-WebUI will be available at http://localhost:8080
echo Press Ctrl+C to stop both servers
echo.

:: Start Ollama server in background if not already running
tasklist /fi "imagename eq ollama.exe" 2>nul | find /i "ollama.exe" >nul
if %errorlevel% equ 0 (
    echo Ollama server is already running.
) else (
    echo Starting Ollama server...
    :: Use direct start without PowerShell to avoid extra windows
    start /b "" "%OLLAMA_EXE%" serve
    
    echo Waiting for Ollama server to initialize...
    timeout /t 3 /nobreak >nul
    echo Ollama server started.
)

:: Change back to script directory
cd /d "%SCRIPT_DIR%"

:: Try to run open-webui serve using different methods
echo.
echo Starting Open-WebUI...

:: Method 1: Direct command (if open-webui command is available)
where open-webui >nul 2>&1
if %errorlevel% equ 0 (
    echo Using open-webui command...
    open-webui serve
    goto success
)

:: Method 2: Using Python module execution
echo Trying python module method...
"%PYTHON_EXE%" -m open_webui serve
if %errorlevel% equ 0 goto success

:: Method 3: Direct Python execution with import
echo Trying direct Python execution...
"%PYTHON_EXE%" -c "from open_webui.main import cli; import sys; sys.argv = ['open-webui', 'serve']; cli()"
if %errorlevel% equ 0 goto success

:: If all methods fail, show error
echo.
echo ERROR: Could not start Open-WebUI
echo.
echo Troubleshooting:
echo 1. Verify open-webui installation:
echo    "%PYTHON_EXE%" -c "import open_webui; print('open-webui is installed')"
echo.
echo 2. Install open-webui if not installed:
echo    "%PYTHON_EXE%" -m pip install open-webui
echo.
echo 3. Check environment activation:
echo    "%PYTHON_EXE%" --version
echo.
echo 4. Try manual installation:
echo    "%PYTHON_EXE%" -m pip install --upgrade open-webui
echo.
pause
goto cleanup_exit

:success
echo Open-WebUI started successfully!
goto cleanup_exit

:cleanup_exit
echo.
echo Shutting down...
echo Stopping Ollama server...
taskkill /f /im ollama.exe 2>nul >nul
if %errorlevel% equ 0 (
    echo Ollama server stopped.
) else (
    echo No Ollama processes found to stop.
)
echo.
echo Goodbye!
pause