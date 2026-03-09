# IXR Laptop Full Setup Script v2
# Auto-discovers ONE gateway from GitHub status.json
# Run in Claude Code: irm https://raw.githubusercontent.com/9Ruby-Git/ops-automation/main/laptop-setup.ps1 | iex

Write-Host "=== IXR Laptop Full Setup ===" -ForegroundColor Cyan

# 1. Discover gateway URL from GitHub
Write-Host "Finding ONE gateway..." -ForegroundColor Yellow
try {
    $status = Invoke-RestMethod "https://raw.githubusercontent.com/9Ruby-Git/ops-automation/main/status.json"
    $gatewayWs = $status.gateway.acp_ws
    $gatewayToken = $status.gateway.token
    Write-Host "  Found: $gatewayWs" -ForegroundColor Green
} catch {
    $gatewayWs = "ws://bore.pub:24970"
    $gatewayToken = "minimax-agent"
    Write-Host "  Using fallback: $gatewayWs" -ForegroundColor Yellow
}

# 2. Fix python3 alias (Claude Code hooks need python3)
Write-Host "Setting up python3..." -ForegroundColor Yellow
$scriptsDir = "C:\Users\VM-openclaw\scripts"
New-Item -ItemType Directory -Force -Path $scriptsDir | Out-Null
$python3Shim = "$scriptsDir\python3.cmd"
"@echo off`npython %*" | Set-Content $python3Shim
Write-Host "  python3 shim created at $python3Shim" -ForegroundColor Green

# Add scripts to PATH
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$scriptsDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$scriptsDir", "User")
    Write-Host "  scripts dir added to PATH" -ForegroundColor Green
}

# 3. Connect to ONE gateway via OpenClaw ACP
Write-Host "Connecting to ONE (Ruby)..." -ForegroundColor Yellow
$openclaw = (Get-Command openclaw -ErrorAction SilentlyContinue)?.Source
if ($openclaw) {
    Start-Process -FilePath $openclaw -ArgumentList "acp --url $gatewayWs --token $gatewayToken" -WindowStyle Hidden
    Write-Host "  ACP started: $gatewayWs" -ForegroundColor Green
} else {
    Write-Host "  OpenClaw not found. Install from: https://openclaw.ai" -ForegroundColor Red
}

# 4. Auto-discover and re-run on bore port change (save current)
$statusFile = "C:\Users\VM-openclaw\.ixr-gateway.json"
$status | ConvertTo-Json | Set-Content $statusFile
Write-Host "  Status cached at $statusFile" -ForegroundColor Green

Write-Host ""
Write-Host "=== Setup Complete ===" -ForegroundColor Green
Write-Host "Gateway: $gatewayWs"
Write-Host "Restart terminal/VS Code for PATH changes to take effect"
