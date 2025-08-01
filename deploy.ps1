# MultiAdScraper - One-Click Deployment from GitHub
# Save as: deploy.ps1
# Run as: powershell -ExecutionPolicy Bypass -File deploy.ps1

param(
    [string]$InstallPath = "$env:USERPROFILE\Desktop\MultiAdScraper"
)

Write-Host "🚀 MultiAdScraper - One-Click Deployment" -ForegroundColor Green
Write-Host "GitHub: https://github.com/Gman1988/MultiAdScraper" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is installed
Write-Host "Checking Docker..." -ForegroundColor Yellow
try {
    $dockerVersion = docker --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Docker found: $dockerVersion" -ForegroundColor Green
    } else {
        throw "Docker not working"
    }
} catch {
    Write-Host "❌ Docker Desktop is not installed or not running!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "1. Download Docker Desktop from: https://www.docker.com/products/docker-desktop/" -ForegroundColor White
    Write-Host "2. Install and start Docker Desktop" -ForegroundColor White
    Write-Host "3. Wait for the whale icon in system tray" -ForegroundColor White
    Write-Host "4. Run this script again" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if git is available
$useGit = $false
try {
    git --version 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $useGit = $true
        Write-Host "✅ Git found - will use git clone" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Git not found - will download ZIP" -ForegroundColor Yellow
}

# Create installation directory
Write-Host ""
Write-Host "Creating installation directory: $InstallPath" -ForegroundColor Yellow
try {
    if (Test-Path $InstallPath) {
        Write-Host "Directory exists, cleaning up..." -ForegroundColor Yellow
        Remove-Item $InstallPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $InstallPath -Force | Out-Null
    Write-Host "✅ Directory created" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to create directory: $InstallPath" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Download project
Write-Host ""
if ($useGit) {
    Write-Host "Cloning repository with Git..." -ForegroundColor Yellow
    try {
        Set-Location (Split-Path $InstallPath -Parent)
        git clone https://github.com/Gman1988/MultiAdScraper.git (Split-Path $InstallPath -Leaf)
        Write-Host "✅ Repository cloned successfully" -ForegroundColor Green
    } catch {
        Write-Host "❌ Git clone failed" -ForegroundColor Red
        $useGit = $false
    }
}

if (-not $useGit) {
    Write-Host "Downloading ZIP from GitHub..." -ForegroundColor Yellow
    try {
        $zipUrl = "https://github.com/Gman1988/MultiAdScraper/archive/refs/heads/main.zip"
        $zipPath = "$env:TEMP\MultiAdScraper.zip"
        
        # Download ZIP
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
        Write-Host "✅ ZIP downloaded" -ForegroundColor Green
        
        # Extract ZIP
        Write-Host "Extracting ZIP..." -ForegroundColor Yellow
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $env:TEMP)
        
        # Move contents to installation directory
        $extractedPath = "$env:TEMP\MultiAdScraper-main"
        if (Test-Path $extractedPath) {
            Get-ChildItem $extractedPath | Move-Item -Destination $InstallPath -Force
            Remove-Item $extractedPath -Recurse -Force
        }
        
        # Cleanup
        Remove-Item $zipPath -Force
        Write-Host "✅ Project extracted successfully" -ForegroundColor Green
        
    } catch {
        Write-Host "❌ Failed to download from GitHub: $_" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
}

# Change to project directory
Set-Location $InstallPath

# Verify essential files exist
$requiredFiles = @("multi_ad_scraper.py", "docker-compose.yml", "Dockerfile", "requirements.txt")
$missingFiles = @()

foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -gt 0) {
    Write-Host "❌ Missing required files:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "   - $_" -ForegroundColor Red }
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ All required files found" -ForegroundColor Green

# Build and start the system
Write-Host ""
Write-Host "Building and starting MultiAdScraper..." -ForegroundColor Yellow
Write-Host "This may take 5-10 minutes on first run (downloading dependencies)..." -ForegroundColor Cyan
Write-Host ""

try {
    # Start Docker Compose
    docker-compose up --build -d
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ MultiAdScraper started successfully!" -ForegroundColor Green
    } else {
        throw "Docker Compose failed"
    }
} catch {
    Write-Host "❌ Failed to start MultiAdScraper" -ForegroundColor Red
    Write-Host "Check the logs with: docker-compose logs" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Wait for services to be ready
Write-Host ""
Write-Host "Waiting for services to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 15

# Check status
Write-Host ""
Write-Host "📊 Service Status:" -ForegroundColor Cyan
try {
    docker-compose ps
} catch {
    Write-Host "Could not check service status" -ForegroundColor Yellow
}

# Test web interface
Write-Host ""
Write-Host "Testing web interface..." -ForegroundColor Yellow
$maxAttempts = 6
$attempt = 1

do {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        Write-Host "✅ Web interface is responding!" -ForegroundColor Green
        $webWorking = $true
        break
    } catch {
        Write-Host "⏳ Attempt $attempt/$maxAttempts - Web interface not ready yet..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        $attempt++
    }
} while ($attempt -le $maxAttempts)

if (-not $webWorking) {
    Write-Host "⚠️  Web interface not responding yet, but containers may still be starting..." -ForegroundColor Yellow
}

# Success summary
Write-Host ""
Write-Host "🎉 Deployment Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Access Points:" -ForegroundColor Cyan
Write-Host "   Main Application: http://localhost:5000" -ForegroundColor White
Write-Host ""
Write-Host "📂 Your Files:" -ForegroundColor Cyan
Write-Host "   Project Folder:   $InstallPath" -ForegroundColor White
Write-Host "   Captured Ads:     $InstallPath\ads_output\" -ForegroundColor White
Write-Host "   System Logs:      $InstallPath\logs\" -ForegroundColor White
Write-Host "   Configuration:    $InstallPath\config.json" -ForegroundColor White
Write-Host ""
Write-Host "🔧 Management Commands:" -ForegroundColor Cyan
Write-Host "   Check Status:     docker-compose ps" -ForegroundColor White
Write-Host "   View Logs:        docker-compose logs -f" -ForegroundColor White
Write-Host "   Stop System:      docker-compose down" -ForegroundColor White
Write-Host "   Start System:     docker-compose up -d" -ForegroundColor White
Write-Host "   Update Project:   git pull && docker-compose up --build -d" -ForegroundColor White
Write-Host ""
Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Open http://localhost:5000 in your browser" -ForegroundColor White
Write-Host "2. Create a free Google Ad Manager account" -ForegroundColor White
Write-Host "3. Add your ad units in the web interface" -ForegroundColor White
Write-Host "4. Watch ads being captured in the ads_output folder" -ForegroundColor White
Write-Host ""

# Open browser automatically
$openBrowser = Read-Host "Open web interface automatically? (y/n)"
if ($openBrowser -eq 'y' -or $openBrowser -eq 'Y' -or $openBrowser -eq '') {
    try {
        Start-Process "http://localhost:5000"
        Write-Host "✅ Browser opened" -ForegroundColor Green
    } catch {
        Write-Host "Could not open browser automatically" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Happy ad scraping! 🚀" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to finish"