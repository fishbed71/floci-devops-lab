# 운영 중인 웹서버 전체에 SSM Run Command 로 셸 명령을 실행한다 (M6).
# Floci 는 --targets Key=tag:... 를 지원하지 않으므로 ASG 의 인스턴스 ID 를 직접 넘긴다.
# 사용:
#   .\provision\ssm-run.ps1                                   # 기본: 앱 상태 확인
#   .\provision\ssm-run.ps1 -Command "bash /var/lib/user-data.sh"   # 프로비저닝 재실행(멱등)

param(
    [string]$Command = 'curl -s localhost:8000/health',
    [string]$AsgName = 'guestbook-dev-web',
    [int]$TimeoutSec = 120
)

# Windows PowerShell 5.1: 네이티브 명령(aws 등)의 stderr 를 예외로 바꾸지 않도록 Continue 로 둔다.
$ErrorActionPreference = 'Continue'

. "$PSScriptRoot\..\scripts\floci-env.ps1"

$ids = (& aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $AsgName `
    --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId" --output text) -split '\s+' |
    Where-Object { $_ }
if (-not $ids) { Write-Error "InService 인스턴스가 없습니다: $AsgName"; exit 1 }
Write-Host "대상: $($ids -join ', ')"

# 명령을 JSON 파라미터 파일로 넘겨 PowerShell 따옴표 문제를 피한다.
$paramFile = Join-Path $env:TEMP "ssm-params-$PID.json"
$json = @{ commands = @($Command) } | ConvertTo-Json -Compress
[IO.File]::WriteAllText($paramFile, $json, (New-Object System.Text.UTF8Encoding($false)))

$commandId = & aws ssm send-command --document-name AWS-RunShellScript --instance-ids $ids `
    --parameters "file://$paramFile" --query Command.CommandId --output text
Remove-Item $paramFile -ErrorAction SilentlyContinue
if ($LASTEXITCODE -ne 0 -or -not $commandId) { exit 1 }
Write-Host "CommandId: $commandId"

$deadline = (Get-Date).AddSeconds($TimeoutSec)
$failed = $false
foreach ($id in $ids) {
    do {
        Start-Sleep -Seconds 2
        $status = & aws ssm get-command-invocation --command-id $commandId --instance-id $id --query Status --output text 2>$null
    } while ($status -in @('Pending', 'InProgress', 'Delayed', '') -and (Get-Date) -lt $deadline)

    $out = & aws ssm get-command-invocation --command-id $commandId --instance-id $id --query StandardOutputContent --output text
    Write-Host "[$id] $status"
    Write-Host ($out -join "`n")
    if ($status -ne 'Success') { $failed = $true }
}
if ($failed) { exit 1 }
