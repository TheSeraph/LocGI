Write-Host ""
Write-Host "-----------------------------------------------------"
Write-Host "The following Ollama environment variables exist"
Get-ChildItem Env: | Out-string -stream | select-string "ollama"


Write-Host ""
Write-Host "Adding Ollama environment variables"
Write-Host ""

# Allow Ollama to be accessed from the network
[Environment]::SetEnvironmentVariable("OLLAMA_HOST", "0.0.0.0", "Machine")

# Change the folder that ollama looks for models in
[Environment]::SetEnvironmentVariable("OLLAMA_MODELS", "T:\ai\models\ollama\", "Machine")

# Allow Ollama to be accessed from obsidian
[Environment]::SetEnvironmentVariable("OLLAMA_ORIGINS", "app://obsidian.md*", "Machine")

Write-Host ""
Write-Host "-----------------------------------------------------"
Write-Host "The following Ollama environment variables exist"
Get-ChildItem Env: | Out-string -stream | select-string "ollama"