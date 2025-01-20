
# Fetching common installation variables from ollama-variables.ps1
. ./ollama-variables.ps1

Write-Host ""
Write-Host "This is is Ollama install checker, intended to be run on Win10/11"
Write-Host "64 bit OS. This will simply check for the existence of $serviceName service"
Write-Host "as well as any paths and environment variables related to Ollama"
Write-Host ""
Write-Host "If you're running this after a removal, please restart your shell or your PC"
Write-Host "To change variables, please edit the variables in ollama-variables.ps1"


Write-Host ""
Write-Host "Checking for $serviceName service..."
if (Get-Service $serviceName) {
    Write-host ""
    Write-Host "The $serviceName service exists. Fetching status"
    Get-Service -Name $serviceName
    $service = Get-Service -Name $serviceName
    $processId = Get-Process | Where-Object {$_.ProcessName -eq $service.Name} | Select-Object -ExpandProperty Id
    Write-Host "The PID for $serviceName is: $processId"
} else {
    Write-Host "The $serviceName service does not exist."
}

write-host ""
write-host "Checking for anything running on port 11434 (Ollama default)"
Get-NetTCPConnection | Where-Object {[int]$_.LocalPort -eq 11434}

Write-Host ""
Write-Host "The following Ollama environment variables exist"
Get-ChildItem Env: | Where-Object {$_.Name -match "ollama"}


Write-Host ""
Write-Host "These are the paths containting Ollama"
$currentPath = ($env:PATH -split ';')
$currentPath | Select-String "Ollama"

