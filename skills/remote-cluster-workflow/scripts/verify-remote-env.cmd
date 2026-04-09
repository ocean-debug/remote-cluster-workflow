@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0verify-remote-env.ps1" %*
