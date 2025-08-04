# Dependencies
. ./ollama-variables.ps1
# This assumes you're running the Ollama server as a service

Write-Host "Downloading latest Win64 Ollama binaries"

curl.exe -LO https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip
Expand-Archive ollama-windows-amd64.zip -Force

Write-Host "Stopping Ollama"
Get-Service -Name $serviceName | Stop-Service -Force

Write-Host "Installing..."
Copy-Item ollama-windows-amd64\* -Destination $OllamaInstallDir -Recurse -Force

Write-Host "Starting Ollama"
Start-Service $serviceName 
ollama -v 

Write-Host "Cleaning up..."
Remove-Item ollama-windows-amd64.zip -Force
Remove-Item ollama-windows-amd64\ -Recurse -Force

