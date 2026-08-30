# Function to get Ollama models
function Get-OllamaModels {
    try {
        $models = ollama ls | ConvertFrom-Csv (ollama ls | Out-String) -Delimiter ' '
        return $models.NAME + ": " + $models.ID
    } catch {
        Write-Error "Failed to retrieve Ollama models: $_"
        return @()
    }
}

# Function to run the test on a model and capture metrics
function Test-Model {
    param (
        [string]$modelName,
        [string]$prompt
    )
    
    try {
        $testCommand = "ollama run --verbose $modelName"
        $output = cmd /c "$testCommand" 2>&1 | Out-String
        # Extract metrics from the output
        $tokensMatch = $output | Select-String 'eval count:.*(\d+)' -CaseInsensitive
        $durationMatch = $output | Select-String 'total duration:.*(\d+\.\d+s)' -CaseInsensitive
        if ($tokensMatch -and $durationMatch) {
            $tokens = [int]$tokensMatch.Matches[0].Groups[1].Value
            $duration = [double]($durationMatch.Matches[0].Groups[1].Value).Split('s')[0]
            $rate = $tokens / $duration
            return @{
                Model = $modelName
                TokensPerSecond = $rate
                Duration = $duration
                Tokens = $tokens
            }
        } else {
            Write-Warning "Could not extract metrics from model: $modelName"
            return @{ Error = "Metrics extraction failed" }
        }
    } catch {
        Write-Error "Test failed for model $modelName: $_"
        return @{ Error = "Test execution failed" }
    }
}

# Main script execution
$models = Get-OllamaModels

if ($models.Count -eq 0) {
    Write-Warning "No models found. Please ensure Ollama is installed and running."
    exit
}

# Display available models with indexes
$modelsWithIndexes = $models | Enumerate-Object -StartIndex 1
Write-Host "Available Models:"
$modelsWithIndexes | Format-Table -AutoSize

# Allow user to select multiple models by index
do {
    Write-Host "`nEnter the indices of the models you want to test (e.g., '1,3,5'), or press Enter to proceed with all models: "
    $input = Read-Host
    if ($input) {
        try {
            $selectedIndices = $input -split ',' | ForEach-Object { [int]$_ }
            $selectedModels = $modelsWithIndexes.Where{ $_.Index -in $selectedIndices } | Select-Object -ExpandProperty Name
            break
        } catch {
            Write-Warning "Invalid indices entered."
        }
    } else {
        # If no input, select all models
        $selectedModels = $models.Name
        break
    }
} until ($selectedModels)

if (-not $selectedModels) {
    Write-Warning "No models were selected. Exiting..."
    exit
}

# Define the test prompt
$testPrompt = @"
1. **Task 1: Information Retrieval**
Extract the following information from the scene:
        * What is the weather like on the island?
        * What are the basic supplies that Max has with him after the shipwreck?

2. **Task 2: Text Generation**
Write a short paragraph (5-7 sentences) describing the island's landscape and climate, using vivid language to help Max understand his surroundings.

3. **Task 3: Conversational Dialogue**
Imagine Max is talking to a local inhabitant of the island who has just approached him. Write a short conversation between Max and the inhabitant, including at least
one question from Max and a response that provides new information about the island's history or dangers.

4. **Task 4: Logical Reasoning**
Max discovers a strange symbol etched into the bark of a tree on the island. Based on this discovery, what might be some possible explanations for its meaning? Write
two to three alternative scenarios (including at least one plausible theory and one more speculative idea) that Max could consider when interpreting the symbol.
"@

# Run tests and collect results
$results = @()
foreach ($model in $selectedModels) {
    $result = Test-Model -modelname $model -prompt $testPrompt
    if ($result.Error) {
        continue  # Skip models with errors
    }
    $results += $result
}

if ($results.Count -eq 0) {
    Write-Warning "No valid results were obtained. Please check the selected models and try again."
    exit
}

# Sort results by tokens per second descending
$sortedResults = $results | Sort-Object -Property TokensPerSecond -Descending

# Display results with ASCII bars (each bar is 50 characters wide)
$maxTokensPSec = ($sortedResults.TokensPerSecond | Measure-Object -Maximum).Maximum
$barWidth = 50

Write-Host "Evaluation Results:" -ForegroundColor Cyan
foreach ($result in $sortedResults) {
    $modelLine = "$($result.Model):"
    $tokensPSecBar = [math]::Round(($result.TokensPerSecond / $maxTokensPSec) * $barWidth)
    $durationBar = [math]::Round(($result.Duration / ($sortedResults.Duration | Measure-Object -Maximum).Maximum) * $barWidth)

    Write-Host ""
    Write-Host "$modelLine`t`tTokens/s: [$('=' * $tokensPSecBar)-$('-' * ($barWidth - $tokensPSecBar))]`t`t{0:.1f} tokens/sec" -f $result.TokensPerSecond
    Write-Host "$modelLine`t`tDuration:  [$('=' * $durationBar)-$('-' * ($barWidth - $durationBar))]`t`t{0}s" -f $result.Duration
}

# Optional: Save results to a CSV file
$saveResults = Read-Host "Would you like to save the results to a CSV file? (Y/N)"
if ($saveResults -match 'y') {
    $timestamp = Get-Date -Format "yyyyMMdd_Hhmmss"
    $fileName = "ollama_model_benchmark_$timestamp.csv"
    $sortedResults | Export-Csv -Path "$fileName" -NoTypeInformation
    Write-Host "Results saved to $fileName"
}