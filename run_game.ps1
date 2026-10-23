# Project WB - run the Godot game (PowerShell version)
# NOTE: double-clicking a .ps1 does NOT run it by default (Windows opens the editor
# for safety). Right-click -> "Run with PowerShell", or run:
#     powershell -ExecutionPolicy Bypass -File run_game.ps1
$Godot = Join-Path $env:USERPROFILE ".workbuddy\tools\godot\Godot_v4.7.2-stable_win64.exe"
if (-not (Test-Path $Godot)) {
    Write-Host "Godot not found at $Godot" -ForegroundColor Red
    Write-Host "Please follow Docs\HOW_TO_RUN.md to download Godot 4.7.2."
    Read-Host "Press Enter to exit"
    exit 1
}
& $Godot --path $PSScriptRoot
