---
name: tf-foundation
description: Terraform provider·backend·versions 와 state 버킷 부트스트랩 생성
module: M3
---

# Terraform 기초 파일 생성

## 사용 시점

M3. `infra/envs/dev` 를 처음 만들 때. 이후 모든 모듈이 이 위에 올라간다.

## 프롬프트

```text
infra/envs/dev 폴더에 Floci 를 대상으로 하는 Terraform 기초 파일을 만들어줘.

1) versions.tf
   - required_version >= 1.10
   - hashicorp/aws ~> 6.0, hashicorp/random ~> 3.6

2) variables.tf
   - region (기본 us-east-1), environment (기본 dev)
   - floci_endpoint (기본 http://localhost:4566)
     validation 으로 localhost, 127.0.0.1, host.docker.internal, floci 만 허용
     → 실수로 실제 AWS 를 가리키지 못하게 하는 가드레일

3) providers.tf
   - access_key/secret_key = "test"
   - skip_credentials_validation, skip_metadata_api_check, s3_use_path_style = true
   - skip_requesting_account_id 는 넣지 말 것 (Floci STS 에서 계정 ID 를 받아야
     보안 그룹 참조 규칙이 매 plan 마다 변경으로 뜨지 않음)
   - endpoints: autoscaling, dynamodb, ec2, elbv2, iam, rds, s3, secretsmanager, ssm, sts
     모두 var.floci_endpoint
   - default_tags: Project, Environment, ManagedBy=terraform

4) backend.tf
   - S3 backend: bucket "tfstate", key "dev/terraform.tfstate", use_lockfile = true
   - endpoints = { s3 = "http://localhost:4566" }, use_path_style = true
   - skip_* 옵션과 access_key/secret_key = "test"
   - 주석: backend 블록에는 변수를 못 쓰므로 주소를 직접 적는다

5) scripts/bootstrap-state.ps1
   - tfstate 버킷이 없으면 만들고, 있으면 건너뛰는 멱등 PowerShell 스크립트
   - aws CLI 사용, 엔드포인트는 http://localhost:4566

주석은 한국어로. 만든 뒤 init/validate 명령을 알려줘.
```

## 검증 명령

```powershell
.\scripts\bootstrap-state.ps1
terraform -chdir=infra/envs/dev init
terraform -chdir=infra/envs/dev validate
aws s3 ls s3://tfstate/dev/          # apply 후 state 파일 확인
```

## 리뷰 체크리스트

- [ ] endpoints 에 실습에서 쓰는 서비스가 빠짐없이 있는가
- [ ] floci_endpoint 에 실제 AWS 주소를 넣으면 validate 가 실패하는가
- [ ] 부트스트랩 스크립트를 두 번 돌려도 오류가 나지 않는가
