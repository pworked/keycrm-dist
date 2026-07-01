# ============================================================
# KeyCRM Helper — встановлення для команди
# Запускати через INSTALL.bat (подвійний клік). Сам підніме права адміністратора.
# ============================================================

# --- НАЛАШТУВАННЯ (заповнюється один раз при зборці) ---
$ExtId = 'aclpkfcdigaaajdmleacfdlmnakbdcen'
$UpdateXmlUrl = 'https://raw.githubusercontent.com/pworked/keycrm-dist/main/dist/update.xml'
# ---------------------------------------------------------

# Піднімаємо права адміністратора, якщо їх немає
$current = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($current)
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
  Write-Host "Потрібні права адміністратора — зараз зʼявиться вікно Windows з питанням. Натисніть 'Так'." -ForegroundColor Yellow
  try {
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -ErrorAction Stop
  } catch {
    Write-Host ""
    Write-Host "Не вдалося піднятись до адміністратора. Або ви натиснули 'Ні' у вікні Windows," -ForegroundColor Red
    Write-Host "або це заблокував антивірус. Спробуйте ще раз і натисніть 'Так'." -ForegroundColor Red
    Read-Host "Натисніть Enter, щоб закрити"
  }
  exit
}

try {
  if ($UpdateXmlUrl -match 'ВАШ_ЛОГІН') {
    throw "install.ps1 не налаштований (URL update.xml не заповнено)."
  }

  $KeyPath = 'HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist'
  if (-not (Test-Path $KeyPath)) {
    New-Item -Path $KeyPath -Force | Out-Null
  }

  # Перевіряємо, чи вже є цей ID (щоб не дублювати), і шукаємо вільний номер
  $existing = Get-Item $KeyPath
  $entry = "$ExtId;$UpdateXmlUrl"
  $alreadyThere = $false
  $maxIndex = 0
  foreach ($name in $existing.Property) {
    $val = (Get-ItemProperty -Path $KeyPath -Name $name).$name
    if ($val -like "$ExtId;*") { $alreadyThere = $true }
    if ($name -match '^\d+$' -and [int]$name -gt $maxIndex) { $maxIndex = [int]$name }
  }

  if ($alreadyThere) {
    Write-Host "KeyCRM Helper вже встановлено через політику. Оновлюю запис на випадок зміни адреси..." -ForegroundColor Cyan
    foreach ($name in $existing.Property) {
      $val = (Get-ItemProperty -Path $KeyPath -Name $name).$name
      if ($val -like "$ExtId;*") {
        Set-ItemProperty -Path $KeyPath -Name $name -Value $entry
      }
    }
  } else {
    $newIndex = $maxIndex + 1
    New-ItemProperty -Path $KeyPath -Name "$newIndex" -Value $entry -PropertyType String -Force | Out-Null
    Write-Host "Додав розширення KeyCRM Helper (позиція $newIndex)." -ForegroundColor Green
  }

  Write-Host ""
  if (Get-Process chrome -ErrorAction SilentlyContinue) {
    $answer = Read-Host "Chrome зараз відкритий. Закрити його зараз, щоб розширення встановилось одразу? (Збережіть важливі вкладки!) [Y/n]"
    if ($answer -eq '' -or $answer -match '^[YyТт]') {
      Get-Process chrome -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
      Start-Sleep -Seconds 1
      Write-Host "Chrome закрито. Відкрийте його знову і зайдіть на KeyCRM — панель зʼявиться автоматично." -ForegroundColor Green
    } else {
      Write-Host "Гаразд, розширення встановиться при наступному запуску Chrome (можна закрити й відкрити пізніше)." -ForegroundColor Yellow
    }
  } else {
    Write-Host "Готово! Відкрийте Chrome і зайдіть на KeyCRM — панель зʼявиться автоматично." -ForegroundColor Green
  }
} catch {
  Write-Host ""
  Write-Host "СТАЛАСЯ ПОМИЛКА:" -ForegroundColor Red
  Write-Host $_.Exception.Message -ForegroundColor Red
  Write-Host ""
  Write-Host "Зробіть скріншот цього вікна і покажіть Pavel." -ForegroundColor Yellow
}
Read-Host "Натисніть Enter, щоб закрити це вікно"
