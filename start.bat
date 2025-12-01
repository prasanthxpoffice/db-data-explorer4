@echo off
setlocal EnableDelayedExpansion

REM ==========================================
REM Configuration
REM ==========================================
set "PROJECT_ROOT=%~dp0"
set "BACKEND_DIR=%PROJECT_ROOT%IAS"
set "BACKEND_PORT=5050"
set "FRONTEND_PORT=8000"
set "START_PAGE=start.html"

echo ==========================================
echo      IAS Application Launcher
echo ==========================================

REM ==========================================
REM 1. Find MSBuild
REM ==========================================
echo [1/5] Locating MSBuild...
set "MSBUILD_PATH="

REM Try vswhere
if exist "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" (
    for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe`) do (
        set "MSBUILD_PATH=%%i"
    )
)

REM Fallback to common paths if vswhere fails or returns nothing
if not defined MSBUILD_PATH (
    if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" set "MSBUILD_PATH=C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe"
    if exist "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe" set "MSBUILD_PATH=C:\Program Files\Microsoft Visual Studio\2022\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe" set "MSBUILD_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\MSBuild\Current\Bin\MSBuild.exe"
    if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe" set "MSBUILD_PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\MSBuild\Current\Bin\MSBuild.exe"
)

if not defined MSBUILD_PATH (
    echo Error: MSBuild not found. Please ensure Visual Studio is installed.
    pause
    exit /b 1
)

echo Found MSBuild: "!MSBUILD_PATH!"

REM ==========================================
REM 2. Build Backend
REM ==========================================
echo [2/5] Building IAS Backend...
"!MSBUILD_PATH!" "%BACKEND_DIR%\IAS.csproj" /p:Configuration=Debug /v:m
if %ERRORLEVEL% NEQ 0 (
    echo Error: Build failed.
    pause
    exit /b 1
)
echo Build successful.

REM ==========================================
REM 3. Start Backend Server (IIS Express)
REM ==========================================
echo [3/5] Starting IAS Backend on port %BACKEND_PORT%...
set "IIS_EXPRESS=%ProgramFiles%\IIS Express\iisexpress.exe"
if not exist "!IIS_EXPRESS!" set "IIS_EXPRESS=%ProgramFiles(x86)%\IIS Express\iisexpress.exe"

if not exist "!IIS_EXPRESS!" (
    echo Error: IIS Express not found.
    pause
    exit /b 1
)

REM Start IIS Express in a new window
start "IAS Backend" "!IIS_EXPRESS!" /path:"%BACKEND_DIR%" /port:%BACKEND_PORT%

REM ==========================================
REM 4. Start Frontend Server
REM ==========================================
echo [4/5] Starting Frontend Server on port %FRONTEND_PORT%...
REM Wait a moment for backend to initialize
timeout /t 3 /nobreak >nul

cd /d "%PROJECT_ROOT%"

REM Try Python
where python >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Using Python http.server...
    start "Frontend Server" python -m http.server %FRONTEND_PORT%
) else (
    REM Try Node http-server
    where npx >nul 2>&1
    if %ERRORLEVEL% EQU 0 (
        echo Using Node http-server...
        start "Frontend Server" npx http-server -p %FRONTEND_PORT%
    ) else (
        echo Error: Neither Python nor Node.js found. Cannot start frontend server.
        echo Please install Python or Node.js.
        pause
        exit /b 1
    )
)

REM ==========================================
REM 5. Launch Browser
REM ==========================================
echo [5/5] Launching Application...
timeout /t 2 /nobreak >nul
start http://localhost:%FRONTEND_PORT%/%START_PAGE%

echo.
echo Application started!
echo Backend: http://localhost:%BACKEND_PORT%
echo Frontend: http://localhost:%FRONTEND_PORT%/%START_PAGE%
echo.
echo Close the server windows to stop the application.
