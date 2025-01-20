$ollamaServerPath = "T:\ai\ollama"
[Environment]::SetEnvironmentVariable("PATH", $env:PATH + ";" + $ollamaServerPath, "Machine")