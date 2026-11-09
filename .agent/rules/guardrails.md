---
trigger: always_on
---
<!-- 자동 생성 파일. AGENTS.md 를 고친 뒤 scripts/sync-agent-prompts.ps1 을 다시 실행하세요. -->

# 에이전트 작업 규칙 (Claude Code · Google Antigravity 공통)

이 저장소는 Floci(로컬 AWS 에뮬레이터) 위에서 Terraform·Docker·GitHub Actions 를 실습하는 교육용 저장소다.
AI 코딩 에이전트는 아래 규칙을 항상 지킨다.

## 절대 규칙

1. **AWS 호출은 Floci 로만.** 모든 AWS 엔드포인트는 `http://localhost:4566` (컨테이너 안에서는 `http://floci:4566`).
   실제 AWS 자격 증명·리전 엔드포인트·`~/.aws` 프로필을 쓰는 코드를 만들지 않는다.
2. **`terraform apply`, `terraform destroy`, `aws ... delete-*`, `docker compose down -v` 는 실행하지 않는다.**
   사람이 실행할 명령을 안내만 한다. `fmt`, `validate`, `plan` 은 실행해도 된다.
3. **비밀값을 코드에 쓰지 않는다.** DB 비밀번호는 `random_password` → Secrets Manager. `.tfvars`, 워크플로, Dockerfile 에 평문 비밀번호 금지.
4. **변경 전에 계획을 보여준다.** 만들거나 바꿀 파일 목록과 이유를 먼저 제시하고, 끝나면 diff 요약과 검증 명령을 제시한다.
5. **버전을 고정한다.** Docker 이미지 태그(`latest` 금지), Terraform provider(`~> 6.0`), GitHub Action(`@v4` 등).

## 저장소 구조

| 경로 | 내용 |
| --- | --- |
| `compose.yaml` | Floci 실행 (4566 API, 8080 ALB, 7001-7020 RDS) |
| `app/` | 방명록 웹앱(`app.py`), `Dockerfile`, 로컬 개발용 `compose.dev.yaml` |
| `infra/modules/{network,web,db}` | Terraform 모듈 |
| `infra/envs/dev` | dev 환경 루트 모듈 (S3 backend 는 Floci) |
| `infra/modules/web/templates/user-data.sh.tftpl` | 웹서버 프로비저닝 스크립트 |
| `provision/` | SSM Run Command 배포 스크립트 |
| `scripts/` | PowerShell 보조 스크립트 |
| `.github/workflows/` | self-hosted runner 용 CI/CD |
| `prompts/` | 바이브코딩 프롬프트 원본 (슬래시 커맨드·워크플로의 원본) |

## Floci 에서 확인된 동작 (코드 생성 시 반영)

- provider `endpoints` 에 쓰는 서비스를 모두 적는다: autoscaling, dynamodb, ec2, elbv2, iam, rds, s3, secretsmanager, ssm, sts.
- provider 에 `skip_requesting_account_id = true` 를 넣지 않는다. 넣으면 SG 참조 규칙이 매 plan 마다 변경으로 뜬다.
- EC2 = Docker 컨테이너. 컨테이너 안에서 IMDS 프록시가 `169.254.169.254:80` 을 점유하므로 **앱은 80 이 아닌 8000 포트**로 리슨한다.
- user_data 는 인스턴스가 running 이 된 뒤 약 1분 후(IMDS·sshd 설정 뒤)에 실행된다. systemd 가 없으므로 백그라운드 프로세스로 띄운다.
- 보안 그룹에 CIDR 기반 인그레스 규칙이 있으면 해당 포트가 호스트 `localhost:30000~` 으로 노출된다.
- ALB HTTP 리스너는 Floci 컨테이너 안에서 열리므로 `compose.yaml` 에 그 포트(8080)를 노출해야 한다.
- RDS 엔드포인트: 호스트에서는 `localhost:7001~`, EC2 컨테이너에서는 출력된 `address:port` 그대로 접속된다.
- 타깃 그룹은 `name_prefix` + `create_before_destroy` 로 만든다 (포트 변경 시 리스너가 사용 중이라 삭제 실패).
- SSM `send-command` 는 `--targets Key=tag:...` 가 아니라 `--instance-ids` 로 대상을 지정한다.
- Auto Scaling 의 CloudWatch 알람 기반 정책은 저장만 되고 동작하지 않는다. 스케일은 desired capacity 변경으로 한다.

## 작업 후 검증 순서

```powershell
terraform -chdir=infra/envs/dev fmt -recursive
terraform -chdir=infra/envs/dev validate
terraform -chdir=infra/envs/dev plan
```
