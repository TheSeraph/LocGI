param(
    [switch]$wipe,      # Delete's Ollama folder before installing new version
    [switch]$noclean,   # Skips the cleanup action afterward file downloads
    [switch]$clean,     # Just runs the cleanup action
    [switch]$nofetch,   # Runs on local files without fetching data
    [switch]$help       # Help instructions
)

# Dependencies
. ./ollama-variables.ps1
# This assumes you're running the Ollama server as a service

Write-Host ""
Write-Host "############################"
Write-Host "### Ollama Update Script ###"
Write-Host "############################"
Write-Host ""

## Help Section

if ($help) {
    Write-Host "Updates an existing Ollama installation using the latest Windows binaries."
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\update-ollama.ps1 [options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -wipe"
    Write-Host "      Deletes all contents of the Ollama installation directory before"
    Write-Host "      installing the new version. Confirmation is required."
    Write-Host ""
    Write-Host "  -noclean"
    Write-Host "      Leaves downloaded ZIP files and extracted folders in place after"
    Write-Host "      installation completes."
    Write-Host ""
    Write-Host "  -clean"
    Write-Host "      Performs only the cleanup operation and exits."
    Write-Host "      Removes downloaded ZIP files and extracted installation folders."
    Write-Host ""
    Write-Host "  -nofetch"
    Write-Host "      Uses locally available installation files and skips downloading"
    Write-Host "      the latest Ollama binaries from GitHub."
    Write-Host ""
    Write-Host "  -help"
    Write-Host "      Displays this help information."
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\update-ollama.ps1"
    Write-Host "      Standard update using the latest downloaded binaries."
    Write-Host ""
    Write-Host "  .\update-ollama.ps1 -wipe"
    Write-Host "      Perform a clean reinstall."
    Write-Host ""
    Write-Host "  .\update-ollama.ps1 -nofetch"
    Write-Host "      Install using files already present in the current directory."
    Write-Host ""
    Write-Host "  .\update-ollama.ps1 -clean"
    Write-Host "      Remove installation artefacts and exit."
    Write-Host ""

    exit 0
}

# Cleanup function for various triggers
function cleanUp {
    Write-Host "Cleaning up..."
    Remove-Item ollama-windows-amd64.zip -Force
    Remove-Item ollama-windows-amd64-rocm.zip -Force
    Remove-Item ollama-windows-amd64-rocm\ -Recurse -Force
    Remove-Item ollama-windows-amd64\ -Recurse -Force
}

# If -clean is used
if ($clean) {
    Write-Host "-clean acvitated, this script will clean up previous installation artifacts"
    cleanUp
    exit 0
}

# If -nofetch is used
if ($nofetch) {
    Write-Host "Skipping fetch"
}
else {
    
    Write-Host "Downloading latest Win64 Ollama binaries (Core + AMD ROCm)"
    # Core
    curl.exe -LO https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip
    # AMD ROCM
    curl.exe -LO https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64-rocm.zip
}

Write-host ""
Write-Host "Ollama install directory is $OllamaInstallDir"
if ($CustomModelPath -eq 1) {
    Write-Host "Ollama models directory is $OllamaModelsPath'"
}
Write-host ""
Write-host "If this is incorrect check the ollama-variables.ps1 file"
Write-host ""

# Stopping ollama to copy files
Write-Host "Stopping Ollama"
Get-Service -Name $serviceName | Stop-Service -Force

# If -wipe is used to remvoe all previous stuff
if ($wipe) {
    Write-host ""
    Write-Host "WARNING: Wipe of Ollama directory has been triggered by -wipe" -ForegroundColor Yellow
    Write-Host "WARNING: Everything in '$OllamaInstallDir' will be permanently deleted." -ForegroundColor Yellow
    if ($CustomModelPath -eq 0) {
        Write-Host "WARNING: Due to your configuration, it is likely that model files will be" -ForegroundColor Red
        Write-Host "deleted by a wipe action." -ForegroundColor Red
    }   

    $confirmation = Read-Host "Are you sure? (Y/no)"

    if ($confirmation -eq 'Y') {
        Remove-Item "$OllamaInstallDir\*" -Recurse -Force
        Write-Host "Directory wiped successfully." -ForegroundColor Green
    }
    else {
        Write-Host "Wipe cancelled." -ForegroundColor Cyan
    }
}

Write-host ""
Expand-Archive ollama-windows-amd64.zip -Force
Write-Host "Installing Ollama Core..."
Copy-Item .\ollama-windows-amd64\* -Destination $OllamaInstallDir -Recurse -Force

Expand-Archive ollama-windows-amd64-rocm.zip -Force
Write-Host "Installing AMD ROCM Ollama Libraries..."
Copy-Item .\ollama-windows-amd64-rocm\* -Destination $OllamaInstallDir -Recurse -Force

Write-Host "Starting Ollama"
Start-Service $serviceName 
ollama -v 

if ($noclean) {
    Write-Host "Skipping clean up as -noclean selected"
}
else {
    cleanUp
}

