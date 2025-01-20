# Get NSSM

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
Write-Host "This little script will download and install NSSM to "$Env:Programfiles"\nssm\"
Write-Host "And create a path. Note that this is only for Win10/11 64bit. Don't run this if"
Write-Host "you already have NSSM installed, and configured with a system path"
Write-Host ""

if (Get-UserConfirmation) {
    Write-Host "Continuing..."
} else {
    Write-Host "Exiting..."
    exit
}

Write-Host ""
Write-Host "Downloading...."
curl.exe -LO https://nssm.cc/release/nssm-2.24.zip
Expand-Archive nssm-2.24.zip -Force
Write-Host ""
Write-Host "Tranferring to "$Env:Programfiles
Copy-Item nssm-2.24\* -Destination $Env:Programfiles -Recurse -Force

Write-Host ""
Write-Host "Creating path"
$NewPath = $Env:Programfiles + "\nssm-2.24\win64\"
Add-MachinePath


Write-Host ""
Write-Host "testing..."
nssm -help


