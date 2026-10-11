param([Parameter(Mandatory = $true)][string]$InstallPath)

$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath($InstallPath)
$required = '启动-Codex CLI.cmd','配置-DeepSeek API Key.cmd','config\config.toml','config\models.json','internal\Launch-Codex.ps1','tools\ocr.py','tools\archive-text.py','tools\check-ocr.py','tools\tesseract\tesseract.exe','projects\AGENTS.md'
foreach ($item in $required) { if (-not (Test-Path -LiteralPath (Join-Path $root $item))) { throw "Missing: $item" } }
& (Join-Path $root '启动-Codex CLI.cmd') --version
if ($LASTEXITCODE -ne 0) { throw 'Codex CLI launch check failed.' }
$languages = & (Join-Path $root 'tools\tesseract\tesseract.exe') --list-langs
foreach ($language in 'chi_sim','chi_tra','eng') { if ($languages -notcontains $language) { throw "Missing OCR language: $language" } }
$env:PYTHONPATH = Join-Path $root 'tools\python'
& python (Join-Path $root 'tools\check-ocr.py')
if ($LASTEXITCODE -ne 0) { throw 'OCR self-check failed.' }
Write-Host 'Installation checks passed.' -ForegroundColor Green
