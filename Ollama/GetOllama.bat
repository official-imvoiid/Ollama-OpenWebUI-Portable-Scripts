@echo off
setlocal EnableDelayedExpansion

:: Step 1: Set the ollama folder in the script's directory
set "OLLAMA_DIR=%~dp0ollama"
set "ZIP_FILE=%OLLAMA_DIR%\ollama-windows-amd64.zip"
set "OUTPUT=%OLLAMA_DIR%\ollama.exe"

:: Step 2: Create the ollama folder if it doesn't exist
if not exist "%OLLAMA_DIR%" (
    mkdir "%OLLAMA_DIR%"
)

:: Step 3: Download ollama-windows-amd64.zip using curl
set "URL=https://ollama.com/download/ollama-windows-amd64.zip"
echo Downloading ollama-windows-amd64.zip to %ZIP_FILE%...
echo.
curl -L "%URL%" -o "%ZIP_FILE%"

:: Step 4: Check if download was successful
if not exist "%ZIP_FILE%" (
    echo Error: Failed to download ollama-windows-amd64.zip
    pause
    exit /b 1
)

:: Step 5: Extract ollama.exe to the ollama folder
echo Extracting ollama.exe to %OLLAMA_DIR%...
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%OLLAMA_DIR%' -Force"

:: Step 6: Check if extraction was successful
if not exist "%OUTPUT%" (
    echo Error: Failed to extract ollama.exe
    pause
    exit /b 1
)

:: Step 7: Delete the zip file
echo Deleting ollama-windows-amd64.zip...
del "%ZIP_FILE%"

:: Step 8: Verify deletion
if exist "%ZIP_FILE%" (
    echo Error: Failed to delete ollama-windows-amd64.zip
) else (
    echo ollama-windows-amd64.zip deleted successfully
)
 
:end
pause