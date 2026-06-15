@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0run_score_docker.ps1" -Run "run_output.json" -Out "score.json" %*
