param(
    [string]$Team = "openrouter-deepseek-v4-flash",
    [string]$Run = "run_output.json",
    [string]$Out = "score.json"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ScoreCandidates = @(
    "bin\practice\observathon-score",
    "bin\practice\observathon-score\observathon-score",
    "bin\public\observathon-score",
    "bin\public\observathon-score\observathon-score",
    "bin\private\observathon-score",
    "bin\private\observathon-score\observathon-score"
)
$LinuxScore = $null
foreach ($Candidate in $ScoreCandidates) {
    $Path = Join-Path $Root $Candidate
    if ((Test-Path -LiteralPath $Path -PathType Leaf)) {
        $LinuxScore = $Path
        $LinuxScoreInContainer = $Candidate -replace "\\", "/"
        break
    }
}
$RunPath = Join-Path $Root $Run
$FindingsPath = Join-Path $Root "solution\findings.json"

if (-not $LinuxScore) {
    Write-Host "Missing Linux score binary:" -ForegroundColor Yellow
    foreach ($Candidate in $ScoreCandidates) {
        Write-Host "  .\$Candidate"
    }
    Write-Host ""
    Write-Host "Download the Linux x64 practice score binary, unzip it, and place it here:"
    Write-Host "  .\bin\practice\observathon-score"
    exit 1
}

if (-not (Test-Path -LiteralPath $RunPath)) {
    Write-Host "Missing run output:" -ForegroundColor Yellow
    Write-Host "  $RunPath"
    Write-Host "Run .\run_practice_docker.cmd first."
    exit 1
}

docker run --rm `
    -v "${Root}:/lab" `
    -w /lab `
    python:3.12-slim `
    bash -c "chmod +x $LinuxScoreInContainer && ./$LinuxScoreInContainer --run $Run --findings solution/findings.json --team $Team --out $Out"
