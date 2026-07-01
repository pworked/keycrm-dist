# ============================================================
# keycrm-DIST\build.ps1
# Запускає ПАВЕЛ після кожної зміни в keycrm-PRODUCTION.
# Пакує розширення в .crx, оновлює update.xml, комітить у git.
# Версію бампати заздалегідь у keycrm-PRODUCTION\manifest.json.
# ============================================================

$ErrorActionPreference = 'Stop'

# --- НАЛАШТУВАННЯ (заповнити один раз після створення GitHub-репо) ---
$RepoRawBase = 'https://raw.githubusercontent.com/pworked/keycrm-dist/main'
# ------------------------------------------------------------

$Root = $PSScriptRoot
$Prod = Join-Path (Split-Path $Root -Parent) 'keycrm-PRODUCTION'
$Build = Join-Path $Root 'build'
$Dist = Join-Path $Root 'dist'
$Pem = Join-Path $Root 'keys\keycrm-helper.pem'
$PubKeyB64 = (Get-Content (Join-Path $Root 'keys\pubkey-b64.txt') -Raw).Trim()
$ExtId = (Get-Content (Join-Path $Root 'keys\ext-id.txt') -Raw).Trim()
$Chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'

if (-not (Test-Path $Pem)) { throw "Немає ключа: $Pem — спершу згенеруйте (keys\genkey.js)." }
if ($RepoRawBase -match 'ВАШ_ЛОГІН') { throw "Заповніть `$RepoRawBase у build.ps1 (URL вашого GitHub-репо)." }

Write-Host "== 1. Копіюю PRODUCTION у staging ==" -ForegroundColor Cyan
if (Test-Path $Build) { Remove-Item $Build -Recurse -Force }
New-Item -ItemType Directory -Path $Build | Out-Null
Copy-Item (Join-Path $Prod '*') $Build -Recurse -Exclude @('*.md')

Write-Host "== 2. Вставляю постійний ключ у manifest.json ==" -ForegroundColor Cyan
$ManifestPath = Join-Path $Build 'manifest.json'
$Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json
$Manifest | Add-Member -NotePropertyName 'key' -NotePropertyValue $PubKeyB64 -Force
$Version = $Manifest.version
$Manifest | ConvertTo-Json -Depth 20 | Set-Content $ManifestPath -Encoding UTF8

Write-Host "== 3. Пакую в .crx (версія $Version) ==" -ForegroundColor Cyan
if (-not (Test-Path $Chrome)) { throw "Не знайдено chrome.exe за шляхом: $Chrome" }
if (Test-Path (Join-Path $Root 'build.crx')) { Remove-Item (Join-Path $Root 'build.crx') -Force }
& $Chrome --pack-extension="$Build" --pack-extension-key="$Pem" | Out-Null
Start-Sleep -Seconds 2

$ProducedCrx = Join-Path $Root 'build.crx'
if (-not (Test-Path $ProducedCrx)) { throw "Chrome не створив build.crx. Перевірте вручну: $Chrome --pack-extension=`"$Build`" --pack-extension-key=`"$Pem`"" }

if (-not (Test-Path $Dist)) { New-Item -ItemType Directory -Path $Dist | Out-Null }
Move-Item $ProducedCrx (Join-Path $Dist 'keycrm-helper.crx') -Force

Write-Host "== 4. Пишу update.xml ==" -ForegroundColor Cyan
$UpdateXml = @"
<?xml version='1.0' encoding='UTF-8'?>
<gupdate xmlns='http://www.google.com/update2/response' protocol='2.0'>
  <app appid='$ExtId'>
    <updatecheck codebase='$RepoRawBase/dist/keycrm-helper.crx' version='$Version' />
  </app>
</gupdate>
"@
Set-Content -Path (Join-Path $Dist 'update.xml') -Value $UpdateXml -Encoding UTF8

Write-Host "== 5. Git commit ==" -ForegroundColor Cyan
Push-Location $Root
git add dist/
git commit -m "release v$Version"
try {
  git push
  Write-Host "Готово! Версія $Version запушена. Колеги отримають оновлення при наступному запуску Chrome." -ForegroundColor Green
} catch {
  Write-Host "Коміт створено, але push не пройшов автоматично. Виконайте вручну: git push" -ForegroundColor Yellow
}
Pop-Location
