@echo off
cd /d "%~dp0.."
powershell -ExecutionPolicy Bypass -File ".\scripts\watch_dashboard.ps1"
