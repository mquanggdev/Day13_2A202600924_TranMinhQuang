@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0run_practice_docker.ps1" -Questions "harness/public_questions.json" -Out "run_output.json" %*
