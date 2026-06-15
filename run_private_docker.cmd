@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0run_practice_docker.ps1" -Phase "private" -Out "run_output.json" %*
