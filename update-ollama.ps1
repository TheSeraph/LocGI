# Dependencies
. ./ollama-variables.ps1
# This assumes you're running the Ollama server as a service

curl.exe -LO https://github.com/ollama/ollama/releases/latest/download/ollama-windows-amd64.zip
Expand-Archive ollama-windows-amd64.zip -Force
Get-Service -Name $serviceName | Stop-Service -Force

Copy-Item ollama-windows-amd64\* -Destination $OllamaInstallDir -Recurse -Force
Start-Service $serviceName 

Remove-Item ollama-windows-amd64.zip -Force
Remove-Item ollama-windows-amd64\ -Recurse -Force

ollama -v 