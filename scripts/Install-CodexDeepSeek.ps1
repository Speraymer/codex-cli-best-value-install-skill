param(
    [string]$InstallPath,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
function Write-Utf8([string]$Path, [string]$Text) { [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding($false))) }
if ([string]::IsNullOrWhiteSpace($InstallPath)) { $InstallPath = Read-Host 'Install location (for example G:\Codex)' }
if ([string]::IsNullOrWhiteSpace($InstallPath)) { throw 'An installation location is required.' }
$root = [IO.Path]::GetFullPath($InstallPath.Trim())
if ((Test-Path -LiteralPath $root) -and -not $Force -and (Get-ChildItem -LiteralPath $root -Force | Select-Object -First 1)) {
    throw "Target is not empty: $root. Choose a new folder, or rerun with -Force only when you intend to update this installation."
}

function Require-Command([string]$Name, [string]$WingetId) {
    $found = Get-Command $Name -ErrorAction SilentlyContinue
    if ($found) { return $found.Source }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { throw "$Name is missing and winget is unavailable. Install it, then run this installer again." }
    winget install --id $WingetId --exact --accept-source-agreements --accept-package-agreements
    $found = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $found) { throw "$Name was installed. Open a new PowerShell window, then rerun this installer." }
    return $found.Source
}

$npm = Require-Command 'npm' 'OpenJS.NodeJS.LTS'
$python = Require-Command 'python' 'Python.Python.3.12'
$skillRoot = Split-Path -Parent $PSScriptRoot
$dirs = 'config','downloads','internal','npm','projects','quick-tools','secrets','temp','tools','tools\python','tools\tesseract','tools\tesseract\tessdata','archives','docs'
$dirs | ForEach-Object { New-Item -ItemType Directory -Force -Path (Join-Path $root $_) | Out-Null }

& $npm install --prefix (Join-Path $root 'npm') '@openai/codex@latest' --no-audit --no-fund
if ($LASTEXITCODE -ne 0) { throw 'Codex CLI installation failed.' }
& $python -m pip install --disable-pip-version-check --target (Join-Path $root 'tools\python') python-docx openpyxl python-pptx reportlab pypdf ddgs playwright pymupdf pillow
if ($LASTEXITCODE -ne 0) { throw 'Python tools installation failed.' }

Copy-Item -LiteralPath (Join-Path $skillRoot 'assets\models.json') -Destination (Join-Path $root 'config\models.json') -Force
Copy-Item -LiteralPath (Join-Path $skillRoot 'assets\tools\*') -Destination (Join-Path $root 'tools') -Force
Copy-Item -LiteralPath (Join-Path $skillRoot 'assets\projects\AGENTS.md') -Destination (Join-Path $root 'projects\AGENTS.md') -Force
Copy-Item -LiteralPath (Join-Path $skillRoot 'assets\docs\使用说明.md') -Destination (Join-Path $root 'docs\使用说明.md') -Force
Get-ChildItem -LiteralPath (Join-Path $root 'tools') -Filter '*.py' | ForEach-Object { Write-Utf8 $_.FullName ((Get-Content -LiteralPath $_.FullName -Raw).Replace('G:\Codex', $root)) }
foreach ($file in @((Join-Path $root 'projects\AGENTS.md'), (Join-Path $root 'docs\使用说明.md'))) { Write-Utf8 $file ((Get-Content -LiteralPath $file -Raw).Replace('G:\Codex', $root)) }

@"
model = "deepseek-v4-pro"
model_provider = "deepseek"
model_reasoning_effort = "high"
web_search = "disabled"
show_raw_agent_reasoning = true
model_catalog_json = "$($root.Replace('\','/'))/config/models.json"

[model_providers.deepseek]
name = "DeepSeek"
base_url = "https://api.deepseek.com/"
wire_api = "responses"

[model_providers.deepseek.auth]
command = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
args = ["-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "$($root.Replace('\','\\'))\\internal\\Get-DeepSeekToken.ps1"]
timeout_ms = 5000
refresh_interval_ms = 300000
"@ | ForEach-Object { Write-Utf8 (Join-Path $root 'config\config.toml') $_ }

@"
`$ErrorActionPreference = 'Stop'
`$env:CODEX_HOME = '$root\config'
`$env:TEMP = '$root\temp'
`$env:TMP = `$env:TEMP
`$env:PYTHONPATH = '$root\tools\python'
& '$root\npm\node_modules\.bin\codex.cmd' @args
exit `$LASTEXITCODE
"@ | ForEach-Object { Write-Utf8 (Join-Path $root 'internal\Launch-Codex.ps1') $_ }

@"
`$ErrorActionPreference = 'Stop'
`$secretPath = '$root\secrets\deepseek.dpapi'
if (-not (Test-Path -LiteralPath `$secretPath)) { throw 'DeepSeek API key is not configured. Run the API Key setup command at the installation root first.' }
`$secureKey = ConvertTo-SecureString -String ((Get-Content -LiteralPath `$secretPath -Raw).Trim())
`$credential = New-Object System.Net.NetworkCredential('', `$secureKey)
try { Write-Output `$credential.Password } finally { `$credential = `$null; `$secureKey.Dispose() }
"@ | ForEach-Object { Write-Utf8 (Join-Path $root 'internal\Get-DeepSeekToken.ps1') $_ }

@"
`$ErrorActionPreference = 'Stop'
Write-Host 'DeepSeek API Key setup' -ForegroundColor Cyan
`$secureKey = Read-Host 'DeepSeek API Key' -AsSecureString
`$credential = New-Object System.Net.NetworkCredential('', `$secureKey)
`$plainKey = `$credential.Password.Trim()
try {
    if (`$plainKey -notmatch '^sk-') { throw 'The key must start with sk-.' }
    `$models = Invoke-RestMethod -Uri 'https://api.deepseek.com/models' -Headers @{ Authorization = "Bearer `$plainKey" } -TimeoutSec 30
    if (-not `$models.data) { throw 'DeepSeek did not return a model list.' }
    `$encrypted = ConvertTo-SecureString -String `$plainKey -AsPlainText -Force | ConvertFrom-SecureString
    [IO.File]::WriteAllText('$root\secrets\deepseek.dpapi', `$encrypted, [Text.Encoding]::ASCII)
    Write-Host 'API authentication succeeded. The key is encrypted for this Windows account.' -ForegroundColor Green
} finally { `$plainKey = `$null; `$credential = `$null; `$secureKey.Dispose() }
"@ | ForEach-Object { Write-Utf8 (Join-Path $root 'internal\Setup-DeepSeek.ps1') $_ }

@"
@echo off`r`npushd "%~dp0projects"`r`npowershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0internal\Launch-Codex.ps1" %*`r`npopd`r`n
"@ | Set-Content -LiteralPath (Join-Path $root '启动-Codex CLI.cmd') -Encoding ascii
@"
@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0internal\Setup-DeepSeek.ps1"`r`npause`r`n
"@ | Set-Content -LiteralPath (Join-Path $root '配置-DeepSeek API Key.cmd') -Encoding ascii

@"
@echo off`r`npushd "%~dp0..\projects"`r`npowershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\internal\Launch-Codex.ps1" --model deepseek-flash %*`r`npopd`r`n
"@ | Set-Content -LiteralPath (Join-Path $root 'quick-tools\Start-Codex-Flash.cmd') -Encoding ascii
@"
@echo off`r`npowershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\internal\Launch-Codex.ps1" %*`r`n
"@ | Set-Content -LiteralPath (Join-Path $root 'quick-tools\Start-Codex-Here.cmd') -Encoding ascii
@"
@echo off`r`nset "PYTHONPATH=%~dp0..\tools\python"`r`npython "%~dp0..\tools\archive-text.py" %*`r`npause`r`n
"@ | Set-Content -LiteralPath (Join-Path $root 'quick-tools\Archive-Text.cmd') -Encoding ascii

@"
param([Parameter(Mandatory = `$true)][string]`$Pdf,[string]`$Prompt='请分析这份 PDF 的内容、结构、表格、图表与关键结论。',[int]`$MaxPages=30)
`$ErrorActionPreference='Stop'; `$pdfPath=(Resolve-Path -LiteralPath `$Pdf).Path
if ([IO.Path]::GetExtension(`$pdfPath) -ne '.pdf') { throw 'Please provide a PDF file.' }
`$name=[IO.Path]::GetFileNameWithoutExtension(`$pdfPath) -replace '[^\w.-]','_'; `$output='$root\temp\pdf-pages\'+`$name+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss')
`$env:PYTHONPATH='$root\tools\python'; `$rendered=python '$root\tools\pdf-to-images.py' `$pdfPath --output `$output --max-pages `$MaxPages | ConvertFrom-Json
if (-not `$rendered.files) { throw 'No PDF pages were rendered.' }; Set-Location (Split-Path `$pdfPath -Parent)
& '$root\internal\Launch-Codex.ps1' --model deepseek-flash --image (`$rendered.files -join ',') "`$Prompt`n`nThe attached images are PDF pages 1 through `$(`$rendered.rendered) of `$(`$rendered.pages)."; exit `$LASTEXITCODE
"@ | ForEach-Object { Write-Utf8 (Join-Path $root 'quick-tools\Analyze-PDF-Flash.ps1') $_ }
@"
@echo off`r`nif "%~1"=="" ( echo Drag a PDF here. & pause & exit /b 1 )`r`npowershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Analyze-PDF-Flash.ps1" -Pdf "%~1" -Prompt "%~2"`r`npause`r`n
"@ | Set-Content -LiteralPath (Join-Path $root 'quick-tools\Analyze-PDF-Flash.cmd') -Encoding ascii

@"
param([Parameter(Mandatory = `$true)][string]`$Pdf,[string]`$Prompt='请完整分析这份 PDF 的内容、结构、表格、图表与关键结论。',[int]`$PagesPerBatch=30)
`$ErrorActionPreference='Stop'; if (`$PagesPerBatch -lt 1) { throw 'PagesPerBatch must be at least 1.' }; `$pdfPath=(Resolve-Path -LiteralPath `$Pdf).Path
if ([IO.Path]::GetExtension(`$pdfPath) -ne '.pdf') { throw 'Please provide a PDF file.' }
`$name=[IO.Path]::GetFileNameWithoutExtension(`$pdfPath) -replace '[^\w.-]','_'; `$work='$root\temp\pdf-full\'+`$name+'-'+(Get-Date -Format 'yyyyMMdd-HHmmss'); New-Item -ItemType Directory -Force -Path `$work|Out-Null
`$env:PYTHONPATH='$root\tools\python'; `$start=1; `$batch=1; `$summaries=@()
while (`$true) { `$dir=Join-Path `$work ('pages-{0:d3}' -f `$batch); `$rendered=python '$root\tools\pdf-to-images.py' `$pdfPath --output `$dir --start-page `$start --max-pages `$PagesPerBatch|ConvertFrom-Json; if (-not `$rendered.files){break}; `$end=`$start+`$rendered.rendered-1; `$summary=Join-Path `$work ('batch-{0:d3}.md' -f `$batch); & '$root\internal\Launch-Codex.ps1' exec --skip-git-repo-check --model deepseek-flash --image (`$rendered.files -join ',') --output-last-message `$summary "Analyze PDF pages `$start through `$end. Original task: `$Prompt`nGive a detailed report and preserve page numbers."; if (`$LASTEXITCODE -ne 0){throw "Flash analysis failed for pages `$start-`$end."}; `$summaries+=`$summary; if (`$end -ge `$rendered.pages){break}; `$start=`$end+1; `$batch++ }
`$reports=Join-Path `$work 'batch-reports.md'; [IO.File]::WriteAllText(`$reports,((`$summaries|ForEach-Object{"`n# `$(Split-Path -Leaf `$_)`n"+(Get-Content -LiteralPath `$_ -Raw)}) -join "`n"),[Text.Encoding]::UTF8); `$final=Join-Path `$work 'final-analysis.md'; Set-Location (Split-Path `$pdfPath -Parent)
& '$root\internal\Launch-Codex.ps1' exec --skip-git-repo-check --model deepseek-v4-pro --output-last-message `$final "Read every batch report in '`$reports' with local shell commands. Then answer: `$Prompt"; if (`$LASTEXITCODE -ne 0){throw 'Final PDF synthesis failed.'}; Get-Content -LiteralPath `$final -Raw
"@ | ForEach-Object { Write-Utf8 (Join-Path $root 'quick-tools\Analyze-PDF-Full.ps1') $_ }
@"
@echo off`r`nif "%~1"=="" ( echo Drag a PDF here. & pause & exit /b 1 )`r`npowershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Analyze-PDF-Full.ps1" -Pdf "%~1" -Prompt "%~2"`r`npause`r`n
"@ | Set-Content -LiteralPath (Join-Path $root 'quick-tools\Analyze-PDF-Full.cmd') -Encoding ascii

$installer = Join-Path $root 'downloads\tesseract-ocr-w64-setup-5.5.0.20241111.exe'
Invoke-WebRequest 'https://github.com/tesseract-ocr/tesseract/releases/download/5.5.0/tesseract-ocr-w64-setup-5.5.0.20241111.exe' -OutFile $installer
Start-Process -FilePath $installer -ArgumentList '/S',("/D=" + (Join-Path $root 'tools\tesseract')) -Wait
if (-not (Test-Path -LiteralPath (Join-Path $root 'tools\tesseract\tesseract.exe'))) { throw 'Tesseract installation did not produce the expected local executable.' }
foreach ($language in 'chi_sim','chi_tra') { Invoke-WebRequest "https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/main/$language.traineddata" -OutFile (Join-Path $root "tools\tesseract\tessdata\$language.traineddata") }

Write-Host "Installed to: $root" -ForegroundColor Green
Write-Host "Next: run '$root\配置-DeepSeek API Key.cmd' and enter your key." -ForegroundColor Yellow
