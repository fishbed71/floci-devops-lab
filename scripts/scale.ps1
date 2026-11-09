# 웹서버 대수(ASG desired capacity)를 바꾸고 InService 개수가 맞을 때까지 기다린다.
# Terraform 은 ignore_changes 로 대수를 관리하지 않으므로 apply 가 이 값을 되돌리지 않는다.
# 사용: .\scripts\scale.ps1 -Desired 3 [-AsgName guestbook-dev-web]

param(
    [Parameter(Mandatory = $true)][ValidateRange(1, 4)][int]$Desired,
    [string]$AsgName = 'guestbook-dev-web',
    [int]$TimeoutSec = 300
)

# Windows PowerShell 5.1: 네이티브 명령(aws 등)의 stderr 를 예외로 바꾸지 않도록 Continue 로 둔다.
$ErrorActionPreference = 'Continue'

. "$PSScriptRoot\floci-env.ps1"

& aws autoscaling set-desired-capacity --auto-scaling-group-name $AsgName --desired-capacity $Desired
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Write-Host "$AsgName desired capacity -> $Desired"

$deadline = (Get-Date).AddSeconds($TimeoutSec)
while ((Get-Date) -lt $deadline) {
    $inService = & aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names $AsgName `
        --query "length(AutoScalingGroups[0].Instances[?LifecycleState=='InService'])" --output text
    Write-Host "InService: $inService / $Desired"
    if ([int]$inService -eq $Desired) {
        Write-Host '완료. 새 인스턴스의 앱은 user_data 실행(약 1~2분) 뒤 응답합니다.'
        exit 0
    }
    Start-Sleep -Seconds 5
}
Write-Error "$TimeoutSec 초 안에 대수가 맞춰지지 않았습니다."
exit 1
