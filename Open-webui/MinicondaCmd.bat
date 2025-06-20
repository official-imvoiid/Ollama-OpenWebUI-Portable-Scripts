@echo off
set PROMPT=()$G
setlocal
cd /D "%~dp0"

set Miniconda=%CD%\installer_files\Miniconda
set Scripts=%CD%\installer_files\Miniconda\Scripts
set Bin=%CD%\installer_files\Miniconda\Library\bin 
set Conda=%CD%\installer_files\Miniconda\_CONDA.exe

:: Set the path temporarily for this session
set PATH=%Miniconda%;%Miniconda%\condabin;%Scripts%;%Bin%;%PATH%

:: Display information and Open command prompt with cleanup instructions
cmd.exe /K "echo Portable Miniconda &echo Envs at %CD%\installer_files\Environments &echo Miniconda Pkgs at %CD%\installer_files\Miniconda\pkgs &echo. &echo Cleanup Instructions: &echo 1. Remove unused packages from cache: conda clean --packages &echo 2. Remove all cached data (packages, tarballs): conda clean --all &echo 3. Remove an environment: conda remove --name ENV_NAME --all &echo 4. List all environments: conda env list &echo. &title Miniconda CMD"