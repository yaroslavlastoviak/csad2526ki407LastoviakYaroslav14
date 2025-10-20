@echo off
setlocal enabledelayedexpansion

rem Parameters (can be overridden via env variables)
if "%BUILD_DIR%"=="" set "BUILD_DIR=build"
if "%CONFIG%"=="" set "CONFIG=Release"

echo [ci] Build directory: %BUILD_DIR%
echo [ci] Configuration:   %CONFIG%

rem 1) Create build directory
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

rem 2) Change into build directory
cd /d "%BUILD_DIR%"

rem 3) Configure project with CMake
cmake -DCMAKE_BUILD_TYPE="%CONFIG%" ..

rem 4) Build the project
cmake --build . --config "%CONFIG%"

echo [ci] Build completed successfully.
endlocal
