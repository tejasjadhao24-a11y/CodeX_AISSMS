# Automate Git and Flutter Installation & Configuration
$ErrorActionPreference = "Stop"

Write-Host "=== Git and Flutter Installer ===" -ForegroundColor Cyan

# 1. Check/Install Git
Write-Host "`n[1/5] Checking Git installation..." -ForegroundColor Yellow
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "Git is already installed and in PATH." -ForegroundColor Green
} else {
    if (Test-Path "C:\Program Files\Git\cmd\git.exe") {
        Write-Host "Git is installed at C:\Program Files\Git\cmd\git.exe but not in PATH. Adding it..." -ForegroundColor Green
    } else {
        Write-Host "Git not found. Installing Git via winget silently..." -ForegroundColor Yellow
        winget install --id Git.Git -e --source winget --accept-source-agreements --accept-package-agreements --silent
        Write-Host "Git installed successfully." -ForegroundColor Green
    }
}

# 2. Download Flutter SDK Stable v3.44.6
$zipUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.44.6-stable.zip"
$zipPath = Join-Path $PSScriptRoot "flutter_temp.zip"

Write-Host "`n[2/5] Downloading Flutter SDK v3.44.6..." -ForegroundColor Yellow
Write-Host "Downloading from: $zipUrl"
Write-Host "Saving temporarily to: $zipPath"

if (Test-Path $zipPath) {
    Write-Host "Temporary zip file already exists, skipping download." -ForegroundColor Green
} else {
    try {
        # Using Start-BitsTransfer for reliable download with progress
        Start-BitsTransfer -Source $zipUrl -Destination $zipPath -Description "Downloading Flutter SDK"
        Write-Host "Download complete." -ForegroundColor Green
    } catch {
        Write-Host "BITS Transfer failed, falling back to WebRequest..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
        Write-Host "Download complete (fallback)." -ForegroundColor Green
    }
}

# 3. Extract Flutter SDK
$destDir = "C:\src"
Write-Host "`n[3/5] Extracting Flutter SDK to $destDir..." -ForegroundColor Yellow
if (-not (Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    Write-Host "Created directory $destDir"
}

if (Test-Path "$destDir\flutter") {
    Write-Host "Existing Flutter SDK folder found at $destDir\flutter. Backing up and replacing..." -ForegroundColor Yellow
    Rename-Item -Path "$destDir\flutter" -NewName "flutter_old_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
}

Expand-Archive -Path $zipPath -DestinationPath $destDir -Force
Write-Host "Extraction complete." -ForegroundColor Green

# 4. Configure PATH Environment Variables
Write-Host "`n[4/5] Configuring environment variables..." -ForegroundColor Yellow
$flutterBin = "C:\src\flutter\bin"
$gitBin = "C:\Program Files\Git\cmd"

# Update persistent User PATH in Registry
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$newPaths = @()
if ($userPath -split ';' -notcontains $flutterBin) { $newPaths += $flutterBin }
if ($userPath -split ';' -notcontains $gitBin) { $newPaths += $gitBin }

if ($newPaths.Count -gt 0) {
    $updatedPath = $userPath + ";" + ($newPaths -join ";")
    # Clean up any potential double semicolons
    $updatedPath = $updatedPath -replace ';+', ';'
    [Environment]::SetEnvironmentVariable("Path", $updatedPath, "User")
    Write-Host "Updated Registry User PATH with: $($newPaths -join ', ')" -ForegroundColor Green
} else {
    Write-Host "PATH is already updated in the Registry." -ForegroundColor Green
}

# Update current process PATH environment
$env:PATH = "$env:PATH;$flutterBin;$gitBin" -replace ';+', ';'

# 5. Clean up & Verification
Write-Host "`n[5/5] Cleaning up temporary files and verifying installation..." -ForegroundColor Yellow
if (Test-Path $zipPath) {
    Remove-Item -Path $zipPath -Force
    Write-Host "Removed temporary zip file."
}

Write-Host "`nVerifying flutter command..." -ForegroundColor Cyan
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    Write-Host "SUCCESS: Flutter CLI is now recognized!" -ForegroundColor Green
    & flutter --version
} else {
    Write-Error "Flutter command is still not recognized. Please restart your terminal/IDE for PATH changes to take effect."
}
