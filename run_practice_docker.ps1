param(
    [int]$Concurrency = 8,
    [string]$Out = "run_output.json",
    [string]$Questions = "",
    [string]$Phase = "practice"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$SimCandidates = @(
    "bin\$Phase\observathon-sim",
    "bin\$Phase\observathon-sim\observathon-sim"
)
$LinuxSim = $null
foreach ($Candidate in $SimCandidates) {
    $Path = Join-Path $Root $Candidate
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        $LinuxSim = $Path
        $LinuxSimInContainer = $Candidate -replace "\\", "/"
        break
    }
}

if (-not $env:OPENAI_API_KEY) {
    Write-Host "OPENAI_API_KEY is not set. Set your OpenRouter key first:" -ForegroundColor Yellow
    Write-Host '$env:OPENAI_API_KEY="sk-or-v1-..."'
    exit 1
}

if (-not $LinuxSim) {
    Write-Host "Missing Linux simulator binary for phase '$Phase':" -ForegroundColor Yellow
    foreach ($Candidate in $SimCandidates) {
        Write-Host "  .\$Candidate"
    }
    Write-Host ""
    Write-Host "Download the Linux x64 $Phase binary, unzip it, and place it under bin\$Phase."
    Write-Host ""
    Write-Host "Do not use observathon-sim.exe with Docker Linux."
    exit 1
}

$QuestionArgs = ""
if ($Questions) {
    $QuestionPath = Join-Path $Root $Questions
    if (-not (Test-Path -LiteralPath $QuestionPath)) {
        Write-Host "Missing questions file:" -ForegroundColor Yellow
        Write-Host "  $QuestionPath"
        exit 1
    }
    $QuestionArgs = "--questions $Questions"
}

docker run --rm `
    -e OPENAI_API_KEY="$env:OPENAI_API_KEY" `
    -e OPENROUTER_API_KEY="$env:OPENAI_API_KEY" `
    -e LOCAL_BASE_URL="http://127.0.0.1:8000/v1" `
    -e LOCAL_API_KEY="$env:OPENAI_API_KEY" `
    -v "${Root}:/lab" `
    -w /lab `
    python:3.12-slim `
    bash -c "python scripts/openrouter_proxy.py & sleep 1 && chmod +x $LinuxSimInContainer && ./$LinuxSimInContainer --config solution/config.json --wrapper solution/wrapper.py --out $Out --concurrency $Concurrency $QuestionArgs"
