$projDir = Join-Path $PSScriptRoot 'freebuff2api'

Write-Host "正在停止 freebuff2api 服务..." -ForegroundColor Yellow

$stopped = @()
Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'server\.js' } |
    ForEach-Object {
        Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
        $stopped += $_.ProcessId
    }

Start-Sleep 1
$left = @(Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
    Where-Object { $_.CommandLine -match 'server\.js' })

if ($left.Count -eq 0) {
    Write-Host "服务已停止" -ForegroundColor Green
} else {
    Write-Host "仍有服务进程未退出，请手动检查" -ForegroundColor Red
}