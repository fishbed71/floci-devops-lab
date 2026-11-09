# Terraform state 용 S3 버킷(tfstate)을 Floci 에 만든다. 이미 있으면 건너뛴다(멱등).
# terraform init 전에 1회 실행. Floci 의 data 폴더를 지웠다면 다시 실행.
# 사용: .\scripts\bootstrap-state.ps1

param([string]$Bucket = 'tfstate')

# Windows PowerShell 5.1: 네이티브 명령(aws 등)의 stderr 를 예외로 바꾸지 않도록 Continue 로 둔다.
$ErrorActionPreference = 'Continue'

. "$PSScriptRoot\floci-env.ps1"

& aws s3api head-bucket --bucket $Bucket 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "state 버킷 '$Bucket' 이 이미 있습니다."
    exit 0
}

& aws s3api create-bucket --bucket $Bucket | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "버킷 생성 실패. Floci 가 실행 중인지 확인: docker ps"; exit 1 }

# state 파일 이력 보존 (실수로 덮어써도 이전 버전 복구 가능)
& aws s3api put-bucket-versioning --bucket $Bucket --versioning-configuration Status=Enabled | Out-Null
Write-Host "state 버킷 '$Bucket' 을 만들었습니다 (버전 관리 켜짐)."
