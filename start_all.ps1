# CampusLift One-Click Launcher
# This script starts the Flask backend and the Public Tunnel

Write-Host "Starting CampusLift Backend Services..." -ForegroundColor Cyan

# 1. Kill existing processes to avoid port conflicts
Stop-Process -Name "python" -ErrorAction SilentlyContinue
Stop-Process -Name "node" -ErrorAction SilentlyContinue

# 2. Start Flask Backend
Write-Host "Launching Flask Server on port 5000..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; venv\Scripts\activate; python app.py" -WindowStyle Minimized

# 3. Start Public Tunnel with fixed subdomain
Write-Host "Launching Public Tunnel (https://campuslift-tejas-789.loca.lt)..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-NoExit", "-Command", "npx localtunnel --port 5000 --subdomain campuslift-tejas-789" -WindowStyle Minimized

Write-Host "`nSUCCESS: All services are running!" -ForegroundColor Green
Write-Host "You can now run your Flutter app."
Write-Host "Backend URL: https://campuslift-tejas-789.loca.lt/api"
