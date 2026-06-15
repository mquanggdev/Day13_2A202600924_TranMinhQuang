@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0run_practice_docker.ps1" -Phase "public" -Out "run_output.json" %*
