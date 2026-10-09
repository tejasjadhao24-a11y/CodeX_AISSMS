# CampusLift - Flutter Build Repair Script
# This script forcefully terminates processes that lock build files and performs a clean setup.

Write-Host "--- CampusLift Flutter Build Repair ---" -ForegroundColor Cyan

# 1. Kill locking processes
Write-Host "[1/3] Terminating locking processes (Dart, Flutter, Chrome)..." -ForegroundColor Yellow
$processes = @("dart", "flutter", "chrome")
foreach ($proc in $processes) {
    if (Get-Process $proc -ErrorAction SilentlyContinue) {
        Write-Host "  Killing $proc..."
        Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
    }
}

# 2. Force delete stubborn directories
Write-Host "[2/3] Cleaning build and cache directories..." -ForegroundColor Yellow
$dirsToClean = @("build", ".dart_tool", ".flutter-plugins", ".flutter-plugins-dependencies")
foreach ($dir in $dirsToClean) {
    if (Test-Path $dir) {
        Write-Host "  Removing $dir..."
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# 3. Refresh dependencies
Write-Host "[3/3] Running flutter pub get..." -ForegroundColor Yellow
flutter pub get

Write-Host "`n--- Repair Complete! ---" -ForegroundColor Green
Write-Host "You can now run 'flutter run -d chrome' safely."
