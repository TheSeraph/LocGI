# List all Ollama variables
Write-Host ""
Write-Host "-----------------------------------------------------"
Write-Host "The following Ollama environment variables exist"
Get-ChildItem Env: | Out-string -stream | select-string "ollama"

# Get the current path seperated by lines
Write-Host ""
Write-Host "-----------------------------------------------------"
Write-Host "Listing current paths which contain ollama"
$currentPath = ($env:PATH -split ';')
$currentPath | select-string "ollama"

# 1. Get Environment Variables Containing "ollama":
$envVarsToRemove = (Get-ChildItem Env: | Where-Object {$_.Name -match "^OLLAMA_"}).Name

Write-Host ""
Write-Host "Removing Ollama environment variables"
Write-Host ""
# 2. Remove Each Matching Variable:
foreach ($varName in $envVarsToRemove) {
    Remove-Item Env:\$varName
    [Environment]::SetEnvironmentVariable($varName, "", "Machine")
}

Write-Host ""
Write-Host "-----------------------------------------------------"
Write-Host "The following Ollama environment variables exist"
Get-ChildItem Env: | Out-string -stream | select-string "ollama"


Write-Host ""
Write-Host "-----------------------------------------------------"
Write-Host "Listing current paths"
$currentPath = ($env:PATH -split ';')
$currentPath | select-string "ollama"
