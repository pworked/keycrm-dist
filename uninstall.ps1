# ============================================================
# KeyCRM Helper — видалення (відкат install.ps1)
# ============================================================

$ExtId = 'aclpkfcdigaaajdmleacfdlmnakbdcen'

$ErrorActionPreference = 'Stop'

$current = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($current)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
  exit
}

$KeyPath = 'HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist'
$removed = $false
if (Test-Path $KeyPath) {
  $existing = Get-Item $KeyPath
  foreach ($name in $existing.Property) {
    $val = (Get-ItemProperty -Path $KeyPath -Name $name).$name
    if ($val -like "$ExtId;*") {
      Remove-ItemProperty -Path $KeyPath -Name $name
      $removed = $true
    }
  }
}

if ($removed) {
  Write-Host "KeyCRM Helper видалено з політики. Закрийте й відкрийте Chrome, щоб розширення зникло." -ForegroundColor Green
} else {
  Write-Host "Запис не знайдено — можливо, вже видалено." -ForegroundColor Yellow
}
Read-Host "Натисніть Enter, щоб закрити це вікно"
