param([switch]$AutoReuse)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$rootDir = $PSScriptRoot
$projDir = Join-Path $rootDir 'freebuff2api'

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  Freebuff2API 一键获取 Key 工具" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# ---------- 1. 环境检查 ----------
Write-Host "[1/5] 检查运行环境..." -ForegroundColor Yellow
$missing = @()
if (-not (Get-Command node -ErrorAction SilentlyContinue)) { $missing += 'Node.js' }
if (-not (Get-Command python -ErrorAction SilentlyContinue)) { $missing += 'Python' }
if ($missing.Count -gt 0) {
    Write-Host "缺少以下软件，请先安装后重试：" -ForegroundColor Red
    foreach ($m in $missing) { Write-Host "  - $m" -ForegroundColor Red }
    if ($missing -contains 'Node.js') {
        Write-Host "安装 Node.js: 打开 https://nodejs.org 下载 LTS 版安装（一路下一步）" -ForegroundColor DarkGray
    }
    if ($missing -contains 'Python') {
        Write-Host "安装 Python: 打开 https://www.python.org/downloads/ 下载安装（勾选 Add to PATH）" -ForegroundColor DarkGray
    }
    Read-Host "按回车退出"
    exit 1
}
Write-Host "  Node: $((node --version))  Python: $((python --version))" -ForegroundColor Green

# ---------- 2. 准备项目代码 ----------
Write-Host "[2/5] 准备项目代码..." -ForegroundColor Yellow
if (-not (Test-Path (Join-Path $projDir 'worker.js'))) {
Write-Host "  首次运行，正在下载项目代码..." -ForegroundColor DarkGray
$zip = Join-Path $env:TEMP 'freebuff2api.zip'
Invoke-WebRequest -Uri 'https://github.com/pingmike2/freebuff2api-wokers/archive/refs/heads/main.zip' -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath $env:TEMP -Force
Move-Item -Path (Join-Path $env:TEMP 'freebuff2api-wokers-main') -Destination $projDir -Force
Remove-Item $zip -Force -ErrorAction SilentlyContinue
    if (-not (Test-Path (Join-Path $projDir 'worker.js'))) {
        Write-Host "项目代码下载失败，请检查网络后重试" -ForegroundColor Red
        Read-Host "按回车退出"
        exit 1
    }
}
Write-Host "  项目就绪: $projDir" -ForegroundColor Green

# ---------- 3. 登录获取 Token ----------
Write-Host "[3/5] 获取 Freebuff 登录 Token..." -ForegroundColor Yellow
$credFile = Join-Path $projDir 'freebuff_tools\freebuff_credentials.json'
$token = $null
if (Test-Path $credFile) {
    $existing = Get-Content $credFile -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($existing.accounts) {
        $acct = $existing.accounts.PSObject.Properties | Select-Object -First 1
        if ($acct) {
            Write-Host "  检测到已有账号: $($acct.Value.name) ($($acct.Value.email))" -ForegroundColor Green
        if ($AutoReuse) { $choice = 'y' } else { $choice = Read-Host "  直接复用该账号? (y=复用 / 其他=重新登录)" }
            if ($choice -eq 'y') { $token = $acct.Value.authToken }
        }
    }
}
if (-not $token) {
    Write-Host "  请在弹出的授权页面完成登录（浏览器里用 Google 账号登录）" -ForegroundColor Cyan
    Write-Host "  ===== 提示：若窗口里没有出现链接，请往下看终端输出 =====`n" -ForegroundColor DarkGray
    Push-Location (Join-Path $projDir 'freebuff_tools')
    try {
        $env:PYTHONUTF8 = '1'
        & python -u extract_freebuff.py login
        if ($LASTEXITCODE -ne 0) { throw "登录流程异常退出 (code $LASTEXITCODE)" }
    }
    finally {
        Pop-Location
        Remove-Item Env:PYTHONUTF8 -ErrorAction SilentlyContinue
    }
    if (Test-Path $credFile) {
        $existing = Get-Content $credFile -Raw -Encoding UTF8 | ConvertFrom-Json
        $acct = $existing.accounts.PSObject.Properties | Select-Object -First 1
        if ($acct) { $token = $acct.Value.authToken }
    }
    if (-not $token) {
        Write-Host "未能获取到 Token（可能授权超时），请重新运行本脚本" -ForegroundColor Red
        Read-Host "按回车退出"
        exit 1
    }
}
Write-Host "  Token 获取成功: $($token.Substring(0,8))...（已隐藏完整）" -ForegroundColor Green

# ---------- 4. 写入配置 ----------
Write-Host "[4/5] 写入配置..." -ForegroundColor Yellow
$credDir = Join-Path $projDir 'credentials'
New-Item -ItemType Directory -Path $credDir -Force | Out-Null
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path $credDir 'account1.json'), ("{`n  `"authToken`": `"$token`"`n}"), $utf8NoBom)
Write-Host "  配置已写入" -ForegroundColor Green

# ---------- 5. 启动服务 ----------
Write-Host "[5/5] 启动服务..." -ForegroundColor Yellow
Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'server\.js' } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
Start-Sleep 1

$env:PORT = '8877'
$env:FREEBUFF_API_KEY = 'freebuff-api'
Start-Process node -ArgumentList 'server.js' -WorkingDirectory $projDir -WindowStyle Hidden `
    -RedirectStandardOutput (Join-Path $projDir 'server.log') `
    -RedirectStandardError (Join-Path $projDir 'server.err.log')

$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep 1
    try {
        $h = Invoke-WebRequest -Uri 'http://localhost:8877/healthz' -TimeoutSec 3 -UseBasicParsing
        if ($h.StatusCode -eq 200) { $ready = $true; break }
    } catch { }
}
if (-not $ready) {
    Write-Host "服务启动失败，请查看 $projDir\server.err.log" -ForegroundColor Red
    Read-Host "按回车退出"
    exit 1
}

# ---------- 输出结果 ----------
Write-Host ""
Write-Host "==============================================" -ForegroundColor Green
Write-Host "  服务启动成功！以下信息用于接入客户端：" -ForegroundColor Green
Write-Host "==============================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Base URL : http://localhost:8877/v1" -ForegroundColor White
Write-Host "  API Key  : freebuff-api" -ForegroundColor White
Write-Host "  模型     : deepseek/deepseek-v4-flash（推荐，不限池）" -ForegroundColor White
Write-Host "           : mimo/mimo-v2.5（推荐，不限池）" -ForegroundColor White
Write-Host ""
Write-Host "  验证命令:" -ForegroundColor DarkGray
Write-Host "    curl http://localhost:8877/healthz" -ForegroundColor DarkGray
Write-Host "    curl http://localhost:8877/v1/models -H \"Authorization: Bearer freebuff-api\"" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  停止服务：双击 一键停止key.bat" -ForegroundColor Yellow
Write-Host "==============================================" -ForegroundColor Green