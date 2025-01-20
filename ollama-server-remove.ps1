
# Fetching common installation variables from ollama-variables.ps1
. ./ollama-variables.ps1

function Get-UserConfirmation {
    param (
        [string]$Prompt = "Do you want to continue?"
    )
    
    while ($true) {
        $response = Read-Host "$Prompt (Y/N)"
        $response = $response.ToUpper()
        
        if ($response -eq "Y") {
            return $true
        } elseif ($response -eq "N") {
            return $false
        } else {
            Write-Host "Invalid input. Please enter Y for yes or N for no."
        }
    }
}


Write-Host ""
Write-Host "This is is Ollama service remover, intended to be run on Win10/11"
Write-Host "64 bit OS. This installer will remove Ollama from $OllamaInstallDir"
Write-Host "remove Ollama environment variables, and delete a service called $serviceName"
write-host "(using NSSM)."
Write-Host ""
Write-Host "There is no error checking in this script. Any previous environmental"
Write-Host "variables with the same name will be over written, and paths will be"
Write-Host "appended/changed. This will also purge all models files if they're located"
Write-Host "in the default directory (normally "$OllamaInstallDir"models\)"
Write-Host ""
Write-Host "To change variables, please edit the variables in ollama-variables.ps1"
Write-Host ""

if (Get-UserConfirmation) {
    Write-Host "Continuing..."
} else {
    Write-Host "Exiting..."
    exit
}

# Stop service
Write-Host ""
Write-Host "Stopping $serviceName"
Get-Service -Name $serviceName | Stop-Service -Force

# Delete service with NSSM
Write-Host ""
Write-Host "Removing Ollama service (NSSM)"

nssm remove $serviceName


# Removing Ollama paths
Write-Host ""
Write-Host "Removing Ollama machine paths"

# Get the current machine-level PATH
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
# Split the machine-level PATH into individual paths
$CurrentPath = $machinePath -split ";"
Write-Host ""
Write-Host "Current list of Machine paths are"
$CurrentPath
# filter out paths that contain "ollama"
$removePath = $currentPath | Select-String "Ollama" | ForEach-Object {$_.Line}
# create a list of paths without the "ollama"
$newPath = $currentPath | Where-Object { $_ -notin $removePath }
Write-Host ""
Write-Host "Paths to be removed are"
$removePath
[Environment]::SetEnvironmentVariable("PATH", ($newPath -join ';'), "Machine")
Write-Host ""
# Set new machine-level path
[Environment]::SetEnvironmentVariable("PATH", ($newPath -join ';'), "Machine")

# Get the current machine-level PATH
$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
# Split the machine-level PATH into individual paths
$CurrentPath = $machinePath -split ";"
Write-Host ""
Write-Host "Current list of Machine paths are"
$CurrentPath

# Removing Ollama environment variables
Write-Host ""
Write-Host "Removing Ollama environment variables"

$envVarsToRemove = (Get-ChildItem Env: | Where-Object {$_.Name -match "^OLLAMA_"}).Name

## 2. Remove Each Matching Variable:
foreach ($varName in $envVarsToRemove) {
    Remove-Item Env:\$varName
    [Environment]::SetEnvironmentVariable($varName, "", "Machine")
}

# Removing Ollama Install
Write-Host ""
Write-Host "Removing Ollama files"
Remove-Item $OllamaInstallDir -Recurse -Force

# Cleanup
Remove-Item nssm-2.24.zip -Force
Remove-Item nssm-2.24\ -Recurse -Force

