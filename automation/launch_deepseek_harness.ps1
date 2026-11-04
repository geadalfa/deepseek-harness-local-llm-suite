# ==============================================================================
# DeepSeek Harness Lifecycle & Zero-Overhead Local LLM Orchestrator
# Part of: DeepSeek Harness Local LLM Suite (github.com/geadalfa/deepseek-harness-local-llm-suite)
# Persona: Gemi AI
# ==============================================================================
[CmdletBinding()]
param(
    [string]$LocalLLMDir = "",
    [string]$DeepSeekHarnessPath = "",
    [string]$OllamaPath = "",
    [int]$TabbyPort = 5000
)

# 1. Resolve Local LLM Directory
if (-not $LocalLLMDir) {
    # Check current script root parent or common drive roots
    $candidates = @(
        (Resolve-Path "$PSScriptRoot\..").Path,
        "I:\LocalLLM",
        "C:\LocalLLM",
        "D:\LocalLLM",
        "$env:USERPROFILE\LocalLLM"
    )
    foreach ($cand in $candidates) {
        if (Test-Path "$cand\tabbyapi\main.py") {
            $LocalLLMDir = $cand
            break
        }
    }
    if (-not $LocalLLMDir) {
        $LocalLLMDir = (Resolve-Path "$PSScriptRoot\..").Path
    }
}

# 2. Resolve Ollama Executable
if (-not $OllamaPath) {
    $ollamaCandidates = @(
        "$env:LOCALAPPDATA\Programs\Ollama\ollama.exe",
        "C:\Program Files\Ollama\ollama.exe",
        "C:\Users\$env:USERNAME\AppData\Local\Programs\Ollama\ollama.exe"
    )
    foreach ($cand in $ollamaCandidates) {
        if (Test-Path $cand) {
            $OllamaPath = $cand
            break
        }
    }
    if (-not $OllamaPath) {
        $ollamaCmd = Get-Command "ollama.exe" -ErrorAction SilentlyContinue
        if ($ollamaCmd) { $OllamaPath = $ollamaCmd.Source }
    }
}

# 3. Resolve DeepSeek Harness Executable
if (-not $DeepSeekHarnessPath) {
    $dshCandidates = @(
        "I:\Program Files (x86)\Deepseek Harness\DeepSeek Harness.exe",
        "C:\Program Files (x86)\Deepseek Harness\DeepSeek Harness.exe",
        "C:\Program Files\Deepseek Harness\DeepSeek Harness.exe",
        "$env:LOCALAPPDATA\Programs\Deepseek Harness\DeepSeek Harness.exe",
        "$env:PROGRAMFILES(X86)\Deepseek Harness\DeepSeek Harness.exe"
    )
    foreach ($cand in $dshCandidates) {
        if (Test-Path $cand) {
            $DeepSeekHarnessPath = $cand
            break
        }
    }
}

# Set Environment Variables for Ollama
$modelsDir = "$LocalLLMDir\models"
if (Test-Path $modelsDir) {
    $env:OLLAMA_MODELS = $modelsDir
}
$env:OLLAMA_API_KEY = "ollama"

# 4. Start Ollama daemon silently if not already running
$ollamaProc = Get-Process -Name "ollama" -ErrorAction SilentlyContinue
if (-not $ollamaProc -and $OllamaPath -and (Test-Path $OllamaPath)) {
    Start-Process -FilePath $OllamaPath -ArgumentList "serve" -WindowStyle Hidden
}

# 5. Start TabbyAPI daemon silently if not already running
$tabbyConnection = Get-NetTCPConnection -LocalPort $TabbyPort -ErrorAction SilentlyContinue
$tabbyPython = "$LocalLLMDir\tabbyapi\venv\Scripts\python.exe"
$tabbyDir = "$LocalLLMDir\tabbyapi"

if (-not $tabbyConnection -and (Test-Path $tabbyPython) -and (Test-Path "$tabbyDir\main.py")) {
    Start-Process -FilePath $tabbyPython -ArgumentList "main.py" -WorkingDirectory $tabbyDir -WindowStyle Hidden
}

# 6. Launch DeepSeek Harness GUI
if ($DeepSeekHarnessPath -and (Test-Path $DeepSeekHarnessPath)) {
    $dshDir = Split-Path -Parent $DeepSeekHarnessPath
    Start-Process -FilePath $DeepSeekHarnessPath -WorkingDirectory $dshDir
} else {
    Write-Warning "DeepSeek Harness executable not found in standard paths. Please verify installation."
}

# 7. Wait for DeepSeek Harness process to spin up
$timeout = 45
$elapsed = 0
while (-not (Get-Process -Name "*deepseek*" -ErrorAction SilentlyContinue) -and ($elapsed -lt $timeout)) {
    Start-Sleep -Seconds 1
    $elapsed++
}

# 8. Monitor Process Loop: While DeepSeek Harness is open, keep local LLMs alive
while (Get-Process -Name "*deepseek*" -ErrorAction SilentlyContinue) {
    Start-Sleep -Seconds 2
}

# 9. DeepSeek Harness Closed! Instantly terminate all Local LLM servers
# Reclaiming 100% RAM & VRAM for zero idle resource consumption
Get-Process -Name "ollama", "ollama app" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

Get-Process -Name "python" -ErrorAction SilentlyContinue | Where-Object { 
    $_.Path -and ($_.Path -like "*tabbyapi*") 
} | Stop-Process -Force -ErrorAction SilentlyContinue
