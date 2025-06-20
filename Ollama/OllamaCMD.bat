@echo off
setlocal enabledelayedexpansion

:: Get current directory and set paths
set "SCRIPT_DIR=%~dp0"
set "OLLAMA_DIR=%SCRIPT_DIR%ollama"
set "OLLAMA_EXE=%OLLAMA_DIR%\ollama.exe"
set "MODELS_DIR=%OLLAMA_DIR%\models"

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

:: Create models directory if it doesn't exist
if not exist "%MODELS_DIR%" mkdir "%MODELS_DIR%"

:: Set environment variables
set "OLLAMA_MODELS=%MODELS_DIR%"
set "PATH=%OLLAMA_DIR%;%PATH%"

:: Change to ollama directory
cd /d "%OLLAMA_DIR%"

:: Check if ollama server is already running
tasklist /fi "imagename eq ollama.exe" | find /i "ollama.exe" >nul
if %errorlevel% equ 0 (
    echo Ollama server is already running.
) else (
    echo Starting Ollama server in background...
    start /min "" powershell -WindowStyle Hidden -Command "cd '%OLLAMA_DIR%'; $env:OLLAMA_MODELS='%MODELS_DIR%'; & '%OLLAMA_EXE%' serve"
    
    :: Wait for server to start
    echo Waiting for server to initialize...
    timeout /t 5 /nobreak >nul
)

:: Display interface
title Ollama Command Interface
cls
echo OLLAMA COMMAND INTERFACE
echo.
echo Working Directory: %OLLAMA_DIR%
echo Ollama Path: %OLLAMA_EXE%
echo Models Directory: %MODELS_DIR%
echo.
echo COMMANDS
echo   ollama list     - List installed models
echo   ollama run      - Run a model (e.g., ollama run llama2)
echo   ollama pull     - Pull/download a model (e.g., ollama pull llama2)
echo   ollama ps       - Show running models
echo   ollama stop     - Stop a running model
echo   help           - Show this help again
echo   clear          - Clear screen
echo   exit           - Exit and stop ollama server
echo.
echo Models are stored in: %MODELS_DIR%

:loop
:: Show current directory in prompt
for %%I in ("%CD%") do set "CURRENT_DIR=%%~nxI"
set /p "cmd=%CURRENT_DIR%> "

:: Handle special commands
if /i "%cmd%"=="exit" goto cleanup
if /i "%cmd%"=="help" goto showhelp
if /i "%cmd%"=="clear" goto clearscreen

:: Handle empty input
if "%cmd%"=="" goto loop

:: Execute the command
echo.
%cmd%
echo.
goto loop

:showhelp
cls
echo COMMANDS
echo   ollama list     - List installed models
echo   ollama run      - Run a model (e.g., ollama run llama2)
echo   ollama pull     - Pull/download a model (e.g., ollama pull llama2)
echo   ollama ps       - Show running models
echo   ollama stop     - Stop a running model
echo   help           - Show this help again
echo   clear          - Clear screen
echo   exit           - Exit and stop ollama server
echo.
goto loop

:clearscreen
cls
echo Ollama Command Interface - Type 'help' for commands
echo.
goto loop

:cleanup
echo.
echo Shutting down Ollama server...
taskkill /f /im ollama.exe 2>nul >nul
if %errorlevel% equ 0 (
    echo Ollama server stopped.
) else (
    echo No Ollama processes found to stop.
)
echo.
echo Goodbye!
pause
exit