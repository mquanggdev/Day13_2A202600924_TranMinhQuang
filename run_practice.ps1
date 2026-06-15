param(
    [int]$Concurrency = 8,
    [string]$Out = "run_output.json"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Sim = Join-Path $Root "bin\practice\observathon-sim.exe"
$Config = Join-Path $Root "solution\config.json"
$Wrapper = Join-Path $Root "solution\wrapper.py"
$OutPath = Join-Path $Root $Out
$RuntimeRoot = Join-Path $Root ".runtime"
$RuntimeTemp = Join-Path $RuntimeRoot "tmp"
$RuntimeSim = Join-Path $RuntimeRoot "observathon-sim.exe"

if (-not $env:LOCAL_BASE_URL) {
    $env:LOCAL_BASE_URL = "https://openrouter.ai/api/v1"
}

if (-not $env:OPENAI_API_KEY) {
    Write-Host "OPENAI_API_KEY is not set. Set your OpenRouter key first:" -ForegroundColor Yellow
    Write-Host '$env:OPENAI_API_KEY="sk-or-v1-..."'
    exit 1
}

if (-not (Test-Path -LiteralPath $Sim)) {
    Write-Host "Missing simulator binary:" -ForegroundColor Yellow
    Write-Host "  $Sim"
    Write-Host ""
    Write-Host "The lab distributes bin/ separately. Put observathon-sim.exe here:"
    Write-Host "  .\bin\practice\observathon-sim.exe"
    exit 1
}

New-Item -ItemType Directory -Force -Path $RuntimeTemp | Out-Null
Get-ChildItem -Path $RuntimeTemp -Directory -Filter "_MEI*" -ErrorAction SilentlyContinue |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

Copy-Item -LiteralPath $Sim -Destination $RuntimeSim -Force
$env:TEMP = $RuntimeTemp
$env:TMP = $RuntimeTemp
$env:PYTHONHOME = ""
$env:PYTHONPATH = ""

try {
    Unblock-File -LiteralPath $Sim -ErrorAction SilentlyContinue
    Unblock-File -LiteralPath $RuntimeSim -ErrorAction SilentlyContinue
} catch {
    # Some locked-down machines do not expose Mark-of-the-Web metadata.
}

$OldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"
$output = & $RuntimeSim --config $Config --wrapper $Wrapper --out $OutPath --concurrency $Concurrency 2>&1
$exitCode = $LASTEXITCODE
$ErrorActionPreference = $OldErrorActionPreference
$combined = ($output | Out-String)

if ($combined) { Write-Host $combined }

if ($combined -match "Failed to load Python DLL" -or $combined -match "Invalid access to memory location") {
    Write-Host ""
    Write-Host "PyInstaller runtime failed before the lab code started." -ForegroundColor Yellow
    Write-Host "This is usually caused by a blocked/corrupt/wrong Windows binary or antivirus blocking the extracted python312.dll."
    Write-Host ""
    Write-Host "Try these fixes:"
    Write-Host "  1. Re-download the Windows bin/practice package."
    Write-Host "  2. If it came from a zip, run: Unblock-File .\that-package.zip before extracting."
    Write-Host "  3. Check Windows Security > Protection history for blocked _MEI*/python312.dll."
    Write-Host "  4. Ask the TA to confirm this SHA256:"
    Get-FileHash -LiteralPath $Sim -Algorithm SHA256 | Format-List
    exit 2
}

exit $exitCode
