@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0invoke-remote-task.ps1" %*
