# IXR Laptop Full Setup Script
# Run this in Claude Code on the laptop

Write-Host "🚀 IXR Laptop Full Setup Starting..." -ForegroundColor Cyan

# 1. Fix Python PATH
Write-Host "📦 Step 1: Fixing Python PATH..."
$pythonPath = (Get-Command python -ErrorAction SilentlyContinue)?.Source
if (-not $pythonPath) {
    $pythonPath = "C:\Users\VM-openclaw\AppData\Local\Programs\Python\Python312\python.exe"
}
if (Test-Path $pythonPath) {
    $pythonDir = Split-Path $pythonPath
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    if ($currentPath -notlike "*$pythonDir*") {
        [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$pythonDir;$pythonDir\Scripts", "User")
        Write-Host "  ✅ Python added to PATH: $pythonDir" -ForegroundColor Green
    } else {
        Write-Host "  ✅ Python already in PATH" -ForegroundColor Green
    }
} else {
    Write-Host "  ⚠️ Python not found. Install from python.org" -ForegroundColor Yellow
}

# Also create python3 alias for Claude Code hooks
$scriptsDir = "C:\Users\VM-openclaw\scripts"
New-Item -ItemType Directory -Force -Path $scriptsDir | Out-Null
$python3Shim = "$scriptsDir\python3.cmd"
@"
@echo off
python %*
"@ | Set-Content $python3Shim
Write-Host "  ✅ python3 shim created" -ForegroundColor Green

# 2. Add scripts to PATH if not there
$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$scriptsDir*") {
    [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$scriptsDir", "User")
    Write-Host "  ✅ Scripts dir added to PATH" -ForegroundColor Green
}

# 3. Connect to ONE gateway via OpenClaw ACP
Write-Host "🔌 Step 2: Connecting to ONE (Ruby) gateway..."
$gatewayUrl = "ws://bore.pub:24970"
$gatewayToken = "minimax-agent"
Write-Host "  Gateway: $gatewayUrl"
Write-Host "  To connect: openclaw acp --url $gatewayUrl --token $gatewayToken"

# Start ACP in background
Start-Process -FilePath "openclaw" -ArgumentList "acp --url $gatewayUrl --token $gatewayToken" -WindowStyle Hidden
Write-Host "  ✅ ACP connection started in background" -ForegroundColor Green

# 4. Setup bore permanently via nssm
Write-Host "🌐 Step 3: Setting up permanent bore tunnel..."
$nssm = (Get-Command nssm -ErrorAction SilentlyContinue)?.Source
$bore = (Get-Command bore -ErrorAction SilentlyContinue)?.Source
if ($nssm -and $bore) {
    # Check if bore service exists
    $svcExists = nssm status bore-tunnel 2>$null
    if ($LASTEXITCODE -ne 0) {
        # Create service
        nssm install bore-tunnel $bore "local 18789 --to bore.pub"
        nssm start bore-tunnel
        Write-Host "  ✅ bore-tunnel service created and started" -ForegroundColor Green
    } else {
        Write-Host "  ✅ bore-tunnel service already exists" -ForegroundColor Green
    }
} else {
    Write-Host "  ⚠️ nssm or bore not found - skipping service install" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Full setup complete!" -ForegroundColor Green
Write-Host "Restart VS Code for PATH changes to take effect."
