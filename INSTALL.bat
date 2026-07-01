@echo off
chcp 65001 >nul
echo Запуск встановлення KeyCRM Helper...
echo (Зараз має зʼявитися вікно Windows з питанням про права адміністратора)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
echo.
echo Якщо вище нічого не написалось або була помилка - зробіть скріншот цього вікна.
pause
