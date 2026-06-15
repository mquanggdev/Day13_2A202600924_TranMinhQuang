# Diagnosis scratchpad

## OpenRouter runtime

Use the lab's local-provider path through the bundled OpenRouter proxy:

```powershell
$env:OPENAI_API_KEY="<OPENROUTER_API_KEY>"
.\run_practice_docker.cmd
```

The selected model is `deepseek/deepseek-v4-flash`, chosen for OpenRouter tool support and low cost. Do not commit API keys.

On Windows, run the helper instead of typing `bin\...` directly:

```powershell
.\run_practice.ps1
```

or:

```cmd
run_practice.cmd
```

If the Windows PyInstaller binary fails to load `python312.dll`, use the Linux binary through Docker Desktop:

```powershell
.\run_practice_docker.ps1
```

or:

```cmd
run_practice_docker.cmd
```

Run the practice simulator, read YOUR telemetry, and note what you find.
Fault classes to hunt: error_spike · latency_spike · cost_blowup · quality_drift ·
infinite_loop · tool_failure · pii_leak.

| symptom (from telemetry) | which requests | suspected cause | config fix? | wrapper fix? |
|---|---|---|---|---|
|  |  |  |  |  |
