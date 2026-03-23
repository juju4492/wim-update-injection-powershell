@echo off
cd /d "%~dp0"

:: Chemin vers le script PowerShell
set ScriptPS1=C:\Users\adv_herrera\Desktop\W11\Scripts\BuildWindowsImage.ps1

:: Vérifie si déjà en admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Elevation requise, relance en mode administrateur...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Lance le script PowerShell
echo Lancement du script PowerShell...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ScriptPS1%"

echo.
echo Script termine. Appuyez sur une touche pour fermer cette fenetre.
pause