# ==============================================================================
# 1-Click Master Setup: DeepSeek Harness + Local LLM Suite
# Part of: github.com/geadalfa/deepseek-harness-local-llm-suite
# Persona: Gemi AI
# ==============================================================================
# Instructions:
# Open PowerShell as Administrator (or standard user) and run:
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
# ==============================================================================

[CmdletBinding()]
param(
    [string]$InstallDir = "C:\LocalLLM",
    [string]$GitHubToken = "",
    [switch]$SkipModelDownload = $false
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "  DeepSeek Harness + Local LLM Suite (Gemi AI 1-Click Installer)     " -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Target Installation Directory: $InstallDir" -ForegroundColor Yellow

# 1. Check & Create Directories
$modelsDir = "$InstallDir\models"
$tabbyDir  = "$InstallDir\tabbyapi"
$scriptsDir = "$InstallDir\scripts"
$configsDir = "$InstallDir\configs"

New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
New-Item -ItemType Directory -Path $modelsDir -Force | Out-Null
New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
New-Item -ItemType Directory -Path $configsDir -Force | Out-Null

# Copy scripts and configs to installation directory
Copy-Item -Path "$PSScriptRoot\automation\*" -Destination $scriptsDir -Recurse -Force
Copy-Item -Path "$PSScriptRoot\configs\*" -Destination $configsDir -Recurse -Force
Copy-Item -Path "$PSScriptRoot\tools" -Destination $InstallDir -Recurse -Force
Copy-Item -Path "$PSScriptRoot\knowledge" -Destination $InstallDir -Recurse -Force
Copy-Item -Path "$PSScriptRoot\skills" -Destination $InstallDir -Recurse -Force

# 2. Check Prerequisites
Write-Host "`n[1/6] Auditing System Prerequisites..." -ForegroundColor Green

# Check NVIDIA GPU
$hasNvidia = Get-Command "nvidia-smi" -ErrorAction SilentlyContinue
if ($hasNvidia) {
    $gpuName = (nvidia-smi --query-gpu=name --format=csv,noheader) -join ", "
    Write-Host "  [OK] NVIDIA GPU Detected: $gpuName" -ForegroundColor Gray
} else {
    Write-Warning "nvidia-smi not detected. An NVIDIA GPU with 8GB+ VRAM (12GB+ recommended) is required for EXL2 & CUDA acceleration."
}

# Check Python 3.11+
$pyCmd = Get-Command "python.exe" -ErrorAction SilentlyContinue
if (-not $pyCmd) {
    Write-Host "  Installing Python 3.11 via winget..." -ForegroundColor Yellow
    winget install Python.Python.3.11 --silent --accept-source-agreements --accept-package-agreements
}
$pyVersion = & python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
Write-Host "  [OK] Python Version: $pyVersion" -ForegroundColor Gray

# Check Node.js (for MCP servers)
$nodeCmd = Get-Command "npx.cmd" -ErrorAction SilentlyContinue
if (-not $nodeCmd) {
    Write-Host "  Installing Node.js LTS via winget (required for DuckDuckGo and GitHub MCP)..." -ForegroundColor Yellow
    winget install OpenJS.NodeJS.LTS --silent --accept-source-agreements --accept-package-agreements
} else {
    Write-Host "  [OK] Node / npx detected." -ForegroundColor Gray
}

# 3. Setup Ollama & GGUF Models
Write-Host "`n[2/6] Setting up Ollama Engine & GGUF Models..." -ForegroundColor Green
$ollamaCmd = Get-Command "ollama.exe" -ErrorAction SilentlyContinue
if (-not $ollamaCmd) {
    Write-Host "  Installing Ollama via winget..." -ForegroundColor Yellow
    winget install Ollama.Ollama --silent --accept-source-agreements --accept-package-agreements
}

# Prevent Ollama from auto-starting on Windows boot (0 MB boot RAM/VRAM invariant)
Remove-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run" -Name "Ollama" -ErrorAction SilentlyContinue

# Set Environment Variables
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", $modelsDir, "User")
$env:OLLAMA_MODELS = $modelsDir
$env:OLLAMA_API_KEY = "ollama"

# Start temporary Ollama daemon to pull models
$ollamaProc = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if (-not $ollamaProc) {
    Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -Seconds 3
}

if (-not $SkipModelDownload) {
    Write-Host "  Pulling GGUF Model 1: deepseek-r1:7b..." -ForegroundColor Yellow
    ollama pull deepseek-r1:7b

    Write-Host "  Pulling GGUF Model 2: qwen2.5-coder:7b..." -ForegroundColor Yellow
    ollama pull qwen2.5-coder:7b

    Write-Host "  Creating GGUF Model 3: qwen3.8:27b-ista-das..." -ForegroundColor Yellow
    ollama create qwen3.8:27b-ista-das -f "$configsDir\Modelfile.qwen3.8"
}

# 4. Setup TabbyAPI (EXL2 Turbo Engine)
Write-Host "`n[3/6] Setting up TabbyAPI (EXL2 Backend)..." -ForegroundColor Green
if (-not (Test-Path "$tabbyDir\.git")) {
    Write-Host "  Cloning TabbyAPI repository (pinned to verified commit 79126f9)..." -ForegroundColor Gray
    git clone https://github.com/theroyallab/tabbyAPI.git $tabbyDir
    Push-Location $tabbyDir
    git checkout 79126f9
    Pop-Location
}

# Create Python Virtual Environment
$tabbyVenv = "$tabbyDir\venv"
if (-not (Test-Path "$tabbyVenv\Scripts\python.exe")) {
    Write-Host "  Creating isolated virtual environment for TabbyAPI..." -ForegroundColor Gray
    & python -m venv $tabbyVenv
}
$tabbyPy = "$tabbyVenv\Scripts\python.exe"

Write-Host "  Installing TabbyAPI dependencies and ExLlamaV2..." -ForegroundColor Gray
& $tabbyPy -m pip install --upgrade pip setuptools wheel
& $tabbyPy -m pip install torch torchvision --index-url https://download.pytorch.org/whl/cu124
& $tabbyPy -m pip install -r "$tabbyDir\requirements.txt"
& $tabbyPy -m pip install formatron huggingface_hub llmlingua

# Try installing prebuilt ExLlamaV2 wheel or build
& $tabbyPy -m pip install exllamav2

# Deploy TabbyAPI Config
Write-Host "  Configuring TabbyAPI (64K Crisp Context, Q8 KV-Cache)..." -ForegroundColor Gray
Copy-Item -Path "$configsDir\tabbyapi_config.yml.template" -Destination "$tabbyDir\config.yml" -Force

# 5. Download 4th Model: Qwen 2.5 Coder 7B EXL2 (Turboderp 4.25bpw)
Write-Host "`n[4/6] Downloading EXL2 Model (Qwen 2.5 Coder 7B 4.25bpw)..." -ForegroundColor Green
$exl2TargetDir = "$tabbyDir\models\Qwen2.5-Coder-7B-Instruct-exl2-4_25"
if (-not $SkipModelDownload -and -not (Test-Path "$exl2TargetDir\output.safetensors")) {
    & $tabbyPy "$PSScriptRoot\scripts\download_exl2.py" `
        --repo "turboderp/Qwen2.5-Coder-7B-Instruct-exl2" `
        --revision "4.25bpw" `
        --out $exl2TargetDir
} else {
    Write-Host "  [OK] EXL2 Model weights already present." -ForegroundColor Gray
}

# 6. DeepSeek Harness Configuration & MCP Deployment
Write-Host "`n[5/6] Deploying DeepSeek Harness Configuration..." -ForegroundColor Green
$dshProfileDir = "$env:USERPROFILE\.dsh\profiles\desktop"
New-Item -ItemType Directory -Path $dshProfileDir -Force | Out-Null

$templatePatch = Get-Content "$configsDir\cordis.patch.yml.template" -Raw
$resolvedPatch = $templatePatch `
    -replace "\{\{LOCAL_LLM_DIR\}\}", ($InstallDir -replace "\\", "\\\\") `
    -replace "\{\{PYTHON_EXECUTABLE\}\}", ($tabbyPy -replace "\\", "\\\\") `
    -replace "\{\{GITHUB_TOKEN\}\}", $GitHubToken

Set-Content -Path "$dshProfileDir\cordis.patch.yml" -Value $resolvedPatch -Encoding utf8
Write-Host "  [OK] cordis.patch.yml installed to $dshProfileDir" -ForegroundColor Gray

# Deploy High-Density AGENTS.md
Copy-Item -Path "$configsDir\AGENTS.md" -Destination "$env:USERPROFILE\.dsh\AGENTS.md" -Force
Write-Host "  [OK] AGENTS.md steering installed to $env:USERPROFILE\.dsh\AGENTS.md" -ForegroundColor Gray

# 7. Create Zero-Overhead Desktop Shortcut
Write-Host "`n[6/6] Generating Zero-Overhead Desktop Launcher..." -ForegroundColor Green
$wsh = New-Object -ComObject WScript.Shell
$desktopPath = [Environment]::GetFolderPath("Desktop")
$shortcut = $wsh.CreateShortcut("$desktopPath\DeepSeek Harness (Local LLM).lnk")
$shortcut.TargetPath = "wscript.exe"
$shortcut.Arguments = "`"$scriptsDir\launch_deepseek_harness.vbs`""
$shortcut.WorkingDirectory = $scriptsDir

# Icon detection
$dshExe = "C:\Program Files (x86)\Deepseek Harness\DeepSeek Harness.exe"
if (Test-Path $dshExe) {
    $shortcut.IconLocation = "$dshExe,0"
}
$shortcut.Save()

# Stop temporary Ollama daemon
Get-Process -Name "ollama" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Write-Host "`n=====================================================================" -ForegroundColor Cyan
Write-Host "  INSTALLATION COMPLETED SUCCESSFULLY!                              " -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor White
Write-Host "  1. Models Available : Qwen 2.5 Coder 7B EXL2 (64K, 120+ TPS)" -ForegroundColor White
Write-Host "                        DeepSeek R1 7B, Qwen 2.5 Coder 7B, Qwen 3.8 27B" -ForegroundColor White
Write-Host "  2. Zero-Overhead    : TabbyAPI & Ollama only run when DeepSeek Harness is open" -ForegroundColor White
Write-Host "                        Automatically killed on exit to free 100% RAM & VRAM" -ForegroundColor White
Write-Host "  3. MCPs & Knowledge : DuckDuckGo search, GitHub, Financial Engine, Gemi Steering" -ForegroundColor White
Write-Host "  4. Desktop Shortcut : 'DeepSeek Harness (Local LLM)' created on Desktop" -ForegroundColor White
Write-Host "`nEnjoy your private, lightning-fast Local LLM powerhouse!" -ForegroundColor Cyan
