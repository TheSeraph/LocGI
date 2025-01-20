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
Write-Host ""
if (Get-UserConfirmation) {
    Write-Host "Continuing..."
    # Set new machine-level path
    [Environment]::SetEnvironmentVariable("PATH", ($newPath -join ';'), "Machine")

    # Get the current machine-level PATH
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    # Split the machine-level PATH into individual paths
    $CurrentPath = $machinePath -split ";"
    Write-Host ""
    Write-Host "Current list of Machine paths are"
    $CurrentPath

} else {
    Write-Host "Exiting..."
    exit
}
    


