# ALB 를 통해 /health 를 반복 호출해 서비스 상태를 확인한다.
# - db 가 ok 인 응답이 나올 때까지 최대 TimeoutSec 동안 기다린다.
# - 응답한 서로 다른 호스트 수와 앱 버전을 출력한다 (로드밸런싱 확인).
# 사용: .\scripts\smoke-test.ps1 [-Url http://localhost:8080] [-TimeoutSec 300] [-MinHosts 1]

param(
    [string]$Url = 'http://localhost:8080',
    [int]$TimeoutSec = 300,
    [int]$MinHosts = 1,
    [int]$Samples = 12
)

# Windows PowerShell 5.1: 네이티브 명령(aws 등)의 stderr 를 예외로 바꾸지 않도록 Continue 로 둔다.
$ErrorActionPreference = 'Continue'

$deadline = (Get-Date).AddSeconds($TimeoutSec)
$ready = $false
while ((Get-Date) -lt $deadline) {
    try {
        $r = Invoke-RestMethod -Uri "$Url/health" -TimeoutSec 5
        if ($r.db -eq 'ok') { $ready = $true; break }
        Write-Host "대기 중: db=$($r.db)"
    } catch {
        Write-Host "대기 중: $($_.Exception.Message)"
    }
    Start-Sleep -Seconds 6
}
if (-not $ready) { Write-Error "$TimeoutSec 초 안에 정상 응답이 없습니다."; exit 1 }

$results = @()
for ($i = 0; $i -lt $Samples; $i++) {
    try { $results += Invoke-RestMethod -Uri "$Url/health" -TimeoutSec 5 } catch { }
}
$hosts    = $results | Where-Object { $_.db -eq 'ok' } | Select-Object -ExpandProperty host -Unique
$versions = $results | Select-Object -ExpandProperty version -Unique

Write-Host "정상 응답 $(@($results | Where-Object { $_.db -eq 'ok' }).Count)/$Samples, 호스트 $(@($hosts).Count)개: $($hosts -join ', ')"
Write-Host "앱 버전: $($versions -join ', ')"

if (@($hosts).Count -lt $MinHosts) {
    Write-Error "응답한 호스트가 $MinHosts 개보다 적습니다."
    exit 1
}
exit 0
