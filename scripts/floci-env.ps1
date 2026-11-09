# 현재 PowerShell 세션의 AWS CLI·SDK 가 Floci 를 가리키게 한다.
# 사용: . .\scripts\floci-env.ps1   (앞의 점과 공백이 중요: 현재 세션에 적용)

$env:AWS_ENDPOINT_URL      = 'http://localhost:4566'
$env:AWS_DEFAULT_REGION    = 'us-east-1'
$env:AWS_REGION            = 'us-east-1'
$env:AWS_ACCESS_KEY_ID     = 'test'
$env:AWS_SECRET_ACCESS_KEY = 'test'
Remove-Item Env:AWS_PROFILE -ErrorAction SilentlyContinue   # 실제 AWS 프로필 사용 방지

Write-Host "AWS CLI -> $env:AWS_ENDPOINT_URL ($env:AWS_DEFAULT_REGION)"
