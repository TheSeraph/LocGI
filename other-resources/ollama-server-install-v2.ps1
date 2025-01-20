
Write-Host ""
Write-Host "This is is Ollama service installer, intended to be run on Win10/11"
Write-Host "64 bit OS. This installer will deploy Ollama to your desired directory"
Write-Host "create Ollama environment variables, and create a service (using NSSM)"
Write-Host ""
# User Confirmation Function
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

if (Get-UserConfirmation) {
    Write-Host "Continuing..."
} else {
    Write-Host "Exiting..."
}


# Ollama Installation Path
#$OllamaInstallDir = "T:\ai\ollama\"
$OllamaInstallDir = Read-Host "Please enter the installation path"
while (!(Validate-InstallPath -Path $OllamaInstallDir)) {
    Write-Host "Invalid path. Please try again."
    $OllamaInstallDir = Read-Host "Please enter the installation path"
}

# Ollama Service Name
#$serviceName = "Ollama"
$serviceName = Read-Host "Please enter the desires service name for Ollama"
if (Get-Service $serviceName) {
    Write-Host "The service name $serviceName already exists."
} else {
    Write-Host "The service does not exist."
}



# Ollama Models Path
Write-Host ""
Write-Host "By default Ollama will store model files in it's installation path." 
Write-Host "However you may wish to store files elsewhere, as they can be large." 
while ($true) {
    $response = Read-Host "Would you like to set a different modelfile storage path? (Y/N)"
    $response = $response.ToUpper()
    
    if ($response -eq "Y") {
        $OllamaModelsPath = Read-Host "Please enter the models path"
        while (!(Validate-InstallPath -Path $OllamaModelsPath)) {
            Write-Host "Invalid path. Please try again."
            $OllamaModelsPath = Read-Host "Please enter the installation path"
        }        
        break
    } elseif ($response -eq "N") {
        Write-Host "Using default model path..."
        break
    } else {
        Write-Host "Invalid input. Please enter Y for yes or N for no."
    }
}


# Pre Installation Checks

## Do Ollama envs already exist
$variableName = "OLLAMA_HOST"
if (Get-Item -Path Env:$variableName -ErrorAction SilentlyContinue) {
    Write-Host "WARNING: The $variableName environment variable exists."
    Get-ChildItem Env: | Out-string -stream | select-string $variableName
    Write-Host "Continuing will overwrite this variable"
    if (Get-UserConfirmation) {
        Write-Host "Continuing..."
    } else {
        Write-Host "Exiting..."
        exit
    }
} else {
    Write-Host "The $variableName environment variable does not exist."
}

$variableName = "OLLAMA_MODELS"
if (Get-Item -Path Env:$variableName -ErrorAction SilentlyContinue) {
    Write-Host "WARNING: The $variableName environment variable exists."
    Get-ChildItem Env: | Out-string -stream | select-string $variableName
    Write-Host "Continuing will overwrite this variable"
    if (Get-UserConfirmation) {
        Write-Host "Continuing..."
    } else {
        Write-Host "Exiting..."
        exit
    }
} else {
    Write-Host "The $variableName environment variable does not exist."
}

# Download & Install Ollama
curl.exe -LO https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip
Expand-Archive ollama-windows-amd64.zip -Force
Copy-Item ollama-windows-amd64\* -Destination $OllamaInstallDir -Recurse -Force

Write-Host ""
Write-Host "Creating paths and environment variables"
Write-Host "-----------------------------------------------"

# Adding Ollama directory to system path
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";" + $OllamaInstallDir, "Machine")

# Allow Ollama to be accessed from the network
[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0", "Machine")

# Change the folder that ollama looks for models in
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", "$OllamaModelsPath", "Machine")

# Get NSSM
Write-Host ""
Write-Host "Downloading Non-sucking Service Manager (NSSM)"
Write-Host "-----------------------------------------------"
curl.exe -LO https://nssm.cc/release/nssm-2.24.zip
Expand-Archive nssm-2.24.zip -Force

## Create Ollama Service with NSSM

Write-Host ""
Write-Host "Installing Ollama service (NSSM)"
Write-Host "-----------------------------------------------"
$OllamaExec = "ollama.exe"
$OllamaServerArguments ="serve"
$nssmInstall = $OllamaInstallDir+$OllamaExec
.\nssm-2.24\nssm-2.24\win64\nssm.exe install $serviceName $nssmInstall $OllamaServerArguments

## Cleanup
Remove-Item nssm-2.24.zip -Force
Remove-Item nssm-2.24\ -Recurse -Force
Remove-Item ollama-windows-amd64.zip -Force
Remove-Item ollama-windows-amd64\ -Recurse -Force

# Start the service
Start-Service $serviceName

