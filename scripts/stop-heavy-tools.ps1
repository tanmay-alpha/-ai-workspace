# Stop Heavy AI/Automation Tools
# Run:
# powershell -ExecutionPolicy Bypass -File scripts\stop-heavy-tools.ps1

Write-Host "Stopping heavy optional tools..." -ForegroundColor Cyan

Write-Host "`nChecking pm2 processes..." -ForegroundColor Yellow
try {
    pm2 status
    Write-Host "Attempting to stop n8n-local..." -ForegroundColor Yellow
    pm2 stop n8n-local
} catch {
    Write-Host "pm2 or n8n-local not available. Skipping." -ForegroundColor DarkYellow
}

Write-Host "`nChecking Ollama models..." -ForegroundColor Yellow
try {
    ollama ps
    Write-Host "Stopping qwen2.5-coder:7b..." -ForegroundColor Yellow
    ollama stop qwen2.5-coder:7b

    Write-Host "Stopping deepseek-r1:7b..." -ForegroundColor Yellow
    ollama stop deepseek-r1:7b
} catch {
    Write-Host "Ollama not available or no models running. Skipping." -ForegroundColor DarkYellow
}

Write-Host "`nDone. Recommended active setup: VS Code + one agent only." -ForegroundColor Green