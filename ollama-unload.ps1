#$postParams = @{"model"="llama3.1:8b-instruct-fp16";"keep_alive"=0}
#Invoke-WebRequest -Uri http://localhost:11434/api/generate -Method POST -Body $postParams


#Invoke-WebRequest -Uri http://localhost:11434/api/generate -Method Post -Body (ConvertTo-Json -InputObject @{model = "deepseek-coder-v2:latest"; keep_alive = 0})

param (
    [string]$model = $null
)

function Write-Color {
    param ([string]$text, [int]$colorCode)
    $coloredText = "$([char]27)[$colorCode;1m$text$([char]27)[0m"
    Write-Host $coloredText #-NoNewline
}

function Show-Spinner {
    $spin = @{ "-" = "\\"; "/" = "|"; "|" = "/"; "\\" = "-"; }
    while ($true) {
        foreach ($key in $spin.Keys) {
            Write-Host -NoNewline "[$($spin[$key])] Processing...`r"
            Start-Sleep -Milliseconds 100
        }
    }
}

try {
    # Execute the command and store the output in a variable
    $OllamaOutput = ollama ps 2>&1 | Out-String
    
    # Convert the output into an array of strings, splitting by newline character
    $lines = $OllamaOutput -split "`n"

    # Check if there are no lines in the output (no process running)
    if ($lines.Count -eq 1) {
        Write-Color "Nothing is running in Ollama currently." 93
    } elseif ($lines.Count -gt 1) {
        # If more than one line, run 'ollama ps' to show processes
        if (-not $model) {
            Write-Color "No model to unload was specified. Currently running models are" 93
            Write-Host ""
            ollama ps
            Write-Host ""
            Write-Host "Please execute this script like 'ollama-unload.ps1 -model <FULL MODEL NAME>' for example "
            Write-Host ""
            exit
        } else {
            $body = @{model = $model; keep_alive = 0 } | ConvertTo-Json
            Invoke-WebRequest -Uri http://localhost:11434/api/generate -Method Post -Body $body
            Write-Host "Checking ollama to see running LLMs..."
            Start-Sleep -Seconds 5
            ollama ps
        }
    } else {
        Write-Host "Error: Unexpected output format from 'ollama ps'."
    }
} catch {
    Write-Host "Error running 'ollama ps': $_"
}





