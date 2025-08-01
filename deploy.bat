@echo off
echo ========================================
echo  MultiAdScraper - Quick Deployment
echo  GitHub: github.com/Gman1988/MultiAdScraper
echo ========================================
echo.

REM Check if Docker is installed
echo Checking Docker...
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Docker is not installed or not running!
    echo.
    echo Please:
    echo 1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/
    echo 2. Install and start Docker Desktop
    echo 3. Wait for whale icon in system tray
    echo 4. Run this script again
    echo.
    pause
    exit /b 1
)
echo ✓ Docker found!

REM Check if git is available
echo.
echo Checking Git...
git --version >nul 2>&1
if %errorlevel% equ 0 (
    echo ✓ Git found - using git clone
    set USE_GIT=1
) else (
    echo ! Git not found - will download ZIP
    set USE_GIT=0
)

REM Set installation path
set INSTALL_PATH=%USERPROFILE%\Desktop\MultiAdScraper

REM Create directory
echo.
echo Creating directory: %INSTALL_PATH%
if exist "%INSTALL_PATH%" (
    echo Directory exists, cleaning up...
    rmdir /s /q "%INSTALL_PATH%" 2>nul
)
mkdir "%INSTALL_PATH%"

REM Download project
echo.
if %USE_GIT%==1 (
    echo Cloning repository...
    cd /d "%USERPROFILE%\Desktop"
    git clone https://github.com/Gman1988/MultiAdScraper.git
    if %errorlevel% neq 0 (
        echo ERROR: Git clone failed
        pause
        exit /b 1
    )
    echo ✓ Repository cloned successfully
) else (
    echo Please download the project manually:
    echo 1. Go to: https://github.com/Gman1988/MultiAdScraper
    echo 2. Click "Code" ^> "Download ZIP"
    echo 3. Extract to: %INSTALL_PATH%
    echo 4. Press Enter when done...
    pause
)

REM Change to project directory
cd /d "%INSTALL_PATH%"

REM Check if essential files exist
echo.
echo Checking files...
if not exist "multi_ad_scraper.py" (
    echo ERROR: multi_ad_scraper.py not found!
    echo Make sure you extracted all files to the correct directory.
    pause
    exit /b 1
)
if not exist "docker-compose.yml" (
    echo ERROR: docker-compose.yml not found!
    pause
    exit /b 1
)
echo ✓ All required files found

REM Start the system
echo.
echo Building and starting MultiAdScraper...
echo This may take 5-10 minutes on first run...
echo.
docker-compose up --build -d

if %errorlevel% neq 0 (
    echo ERROR: Failed to start MultiAdScraper
    echo Check logs with: docker-compose logs
    pause
    exit /b 1
)

echo.
echo ✓ MultiAdScraper started successfully!

REM Wait and check status
echo.
echo Waiting for services to start...
timeout /t 15 /nobreak >nul

echo.
echo Service Status:
docker-compose ps

REM Success message
echo.
echo ========================================
echo           DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo Access Points:
echo   Main Application: http://localhost:5000
echo.
echo Your Files:
echo   Project Folder:   %INSTALL_PATH%
echo   Captured Ads:     %INSTALL_PATH%\ads_output\
echo   System Logs:      %INSTALL_PATH%\logs\
echo.
echo Management Commands:
echo   Check Status:     docker-compose ps
echo   View Logs:        docker-compose logs -f
echo   Stop System:      docker-compose down
echo   Start System:     docker-compose up -d
echo.
echo Next Steps:
echo 1. Open http://localhost:5000 in your browser
echo 2. Create a Google Ad Manager account (free)
echo 3. Add your ad units in the web interface
echo 4. Watch ads being captured!
echo.

REM Ask to open browser
set /p OPEN_BROWSER="Open web interface now? (y/n): "
if /i "%OPEN_BROWSER%"=="y" (
    start http://localhost:5000
    echo ✓ Browser opened
)

echo.
echo Happy ad scraping! 🚀
echo.
pause