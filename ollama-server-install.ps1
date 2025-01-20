
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

function Add-MachinePath {
    # Get the current machine-level PATH
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")

    # Split the machine-level PATH into individual paths
    $paths = $machinePath -split ";"

    # Check if the new path is already in the list of machine-level paths
    if ($paths -notcontains $NewPath) {
        # Add the new path to the machine-level PATH
        $newMachinePath = $machinePath + ";" + $NewPath
        [Environment]::SetEnvironmentVariable("PATH", $newMachinePath, "Machine")
    } else {
        Write-Host "$NewPath is already in the machine-level PATH."
    }
}


Write-Host ""
Write-Host "This is is Ollama service installer, intended to be run on Win10/11"
Write-Host "64 bit OS. This installer will deploy Ollama to $OllamaInstallDir"
Write-Host "create Ollama environment variables, and create a service called $serviceName"
write-host "(using NSSM)."
Write-Host ""
Write-Host "There is no error checking in this script. Any previous environmental"
Write-Host "variables with the same name will be over written, and paths will be"
Write-Host "appended"
Write-Host ""
Write-Host "To change variables, please edit the variables in ollama-variables.ps1"
Write-Host ""



# Download & Install Ollama
curl.exe -LO https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip
Expand-Archive ollama-windows-amd64.zip -Force
Copy-Item ollama-windows-amd64\* -Destination $OllamaInstallDir -Recurse -Force

Write-Host ""
Write-Host "Creating paths and environment variables"
Write-Host "-----------------------------------------------"

# Adding Ollama directory to system path
$NewPath = $OllamaInstallDir
Add-MachinePath

# Allow Ollama to be accessed from the network
[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0", "Machine")

# Setting Ollama model files folder. This is defined in the ollama-variables.ps1 file"
if ($CustomModelPath -eq 1) {
    Write-Host "Custom path for models is "$OllamaModelsPath
    [Environment]::SetEnvironmentVariable("OLLAMA_MODELS", "$OllamaModelsPath", "Machine")
} else {
    Write-Host "No custom path for models selected"
}


## Create Ollama Service with NSSM

Write-Host ""
Write-Host "Installing Ollama service (NSSM)"
Write-Host "-----------------------------------------------"
$OllamaExec = "ollama.exe"
$OllamaServerArguments ="serve"
$nssmInstall = $OllamaInstallDir+$OllamaExec
nssm install $serviceName $nssmInstall $OllamaServerArguments 
nssm set $serviceName description "Ollama inferencing enging local service, started on boot. Created by NSSM"

## Cleanup
Remove-Item ollama-windows-amd64.zip -Force
Remove-Item ollama-windows-amd64\ -Recurse -Force

# Start the service
Start-Service -Name $serviceName

