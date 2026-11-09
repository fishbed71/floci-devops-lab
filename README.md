# Floci DevOps Lab

Windows 11 노트북 한 대에서 **AWS 계정 없이** 웹서버·DB 인프라를 코드로 만들고, 스케일을 조정하고,
GitHub Actions self-hosted runner 로 배포까지 하는 실습 저장소입니다.
[Floci 기반 로컬 클라우드 DevOps 교육과정](https://claude.ai/artifact/84epSHdb431gFTGzWgdHie)의 참조 구현(강사용 정답)이며,
수강생은 `prompts/` 의 프롬프트로 같은 결과물을 AI 와 함께 직접 만들어 갑니다.

```
브라우저 ─▶ localhost:8080 (ALB) ─▶ ASG 웹서버 ×N (EC2 = 컨테이너, :8000) ─▶ RDS PostgreSQL
                     ▲                                                  ▲
       Terraform / AWS CLI / self-hosted runner ──▶ Floci (localhost:4566) ──▶ Docker Desktop
```

## 구성

| 경로 | 내용 |
| --- | --- |
| [compose.yaml](compose.yaml) | Floci 2.4.0 실행 (4566 API, 8080 ALB, 7001-7020 RDS) |
| [app/](app) | 방명록 웹앱 `app.py`, `Dockerfile`, 로컬 개발용 `compose.dev.yaml` |
| [infra/modules/network](infra/modules/network) | VPC, 서브넷 4개, 보안 그룹 3개 |
| [infra/modules/web](infra/modules/web) | Launch Template + ASG + ALB, user_data 템플릿 |
| [infra/modules/db](infra/modules/db) | RDS PostgreSQL 16 + Secrets Manager |
| [infra/envs/dev](infra/envs/dev) | dev 환경 (state 는 Floci S3) |
| [scripts/](scripts) | 환경변수, state 버킷, 스모크 테스트, 스케일, 프롬프트 동기화 |
| [provision/](provision) | SSM Run Command 실행 스크립트 |
| [.github/workflows/](.github/workflows) | `infra-ci`, `infra-cd`, `app-ci`, `scale` |
| [prompts/](prompts) | 바이브코딩 프롬프트 18개 (생성 9 · 관리 9) |
| [AGENTS.md](AGENTS.md), [CLAUDE.md](CLAUDE.md), `.agent/` | Claude Code·Antigravity 공통 규칙과 슬래시 커맨드 |
| [docs/](docs) | runner 설치, 트러블슈팅 |

## 빠른 시작 (PowerShell)

사전 설치: Docker Desktop(WSL2), Terraform ≥ 1.10, AWS CLI v2, Git.

```powershell
winget install Hashicorp.Terraform Amazon.AWSCLI Git.Git GitHub.cli
```

1. Floci 기동

    ```powershell
    docker compose up -d
    . .\scripts\floci-env.ps1          # 현재 세션의 AWS CLI 를 Floci 로
    ```

2. state 버킷 만들고 배포 (약 2분)

    ```powershell
    .\scripts\bootstrap-state.ps1
    terraform -chdir=infra/envs/dev init
    terraform -chdir=infra/envs/dev apply
    ```

3. 확인: 웹서버는 user_data 실행까지 1~2분 걸립니다.

    ```powershell
    .\scripts\smoke-test.ps1 -MinHosts 2
    start http://localhost:8080
    ```

4. 스케일

    ```powershell
    .\scripts\scale.ps1 -Desired 4                       # 수평: 대수
    # 수직: infra/envs/dev/terraform.tfvars 의 web_instance_type 을 바꾸고 apply
    ```

5. 정리

    ```powershell
    terraform -chdir=infra/envs/dev destroy
    ```

## 바이브코딩 프롬프트

Claude Code 에서는 `/tf-network`, Antigravity 에서는 `/tf-network` 워크플로처럼 실행합니다.
목록과 사용법은 [prompts/README.md](prompts/README.md) 에 있습니다.
프롬프트를 고쳤으면 커맨드 파일을 다시 생성합니다.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-agent-prompts.ps1
```

## 교육과정 모듈과 파일

| 모듈 | 주제 | 프롬프트 | 결과 파일 |
| --- | --- | --- | --- |
| M1 | 로컬 클라우드와 Floci | `/floci-compose` | `compose.yaml` |
| M2 | 바이브코딩 기초 | `/app-docker`, `/docker-review` | `app/`, `AGENTS.md` |
| M3 | Terraform 기초 | `/tf-foundation`, `/plan-review` | `infra/envs/dev/{versions,providers,backend}.tf` |
| M4 | 네트워크와 웹서버 | `/tf-network`, `/tf-web-single`, `/tf-refactor` | `infra/modules/network` |
| M5 | DB 서버 | `/tf-db` | `infra/modules/db` |
| M6 | 프로비저닝 | `/provisioning` | `user-data.sh.tftpl`, `provision/ssm-run.ps1` |
| M7 | 스케일 조정 | `/tf-web-asg`, `/scale-change`, `/drift-check` | `infra/modules/web`, `scripts/scale.ps1` |
| M8 | Self-hosted runner | — | [docs/runner-setup.md](docs/runner-setup.md) |
| M9 | CI/CD | `/gha-workflows`, `/security-review` | `.github/workflows/` |
| M10 | 캡스톤 | `/diagnose`, `/cleanup`, `/real-aws-diff` | 전체 |

## 검증 기록 (2026-11-09)

Windows 11 Pro, Docker Desktop 29.7.2(4 CPU, 8 GB), Floci 2.4.0, Terraform 1.17.1, AWS provider 6.72.0 에서 확인했습니다.
워크플로는 같은 PC 의 self-hosted runner 2.338.2 (Windows PowerShell 5.1, Terraform 1.17.0, AWS CLI 2.39.5) 에서 실행했습니다.

| 항목 | 결과 |
| --- | --- |
| `terraform apply` (빈 상태 → 29개 리소스) | 성공, 약 2분 |
| apply 직후 `terraform plan` | `No changes` |
| ALB `localhost:8080` 라운드로빈 | 2~4대 모두 응답, DB 연결 ok |
| 수평 스케일 2 → 4 (`set-desired-capacity`) | 약 80초 뒤 4대 응답, 이후 plan `No changes` |
| 수직 스케일 t3.micro → t3.medium | instance refresh, 컨테이너 메모리 제한 1 GiB → 4 GiB |
| 앱 변경 → launch template 새 버전 | instance refresh 로 전체 교체 (동시 교체라 1~2분 중단) |
| SSM Run Command (`provision/ssm-run.ps1`) | 3대 모두 Success, user_data 재실행 멱등 |
| `app/compose.dev.yaml` | 이미지 235 MB, uid 10001, `/health` ok |
| `terraform destroy` | 29개 삭제, 남은 컨테이너 없음 |
| `infra-ci` (PR) | fmt·validate·plan 성공, PR 에 plan 코멘트 게시 (약 1분 20초) |
| `app-ci` (PR) | 이미지 빌드 + PostgreSQL 스모크 3/3, 테스트 컨테이너 정리 확인 |
| `infra-cd` (수동) | `confirm=yes` 는 job 건너뜀, `confirm=apply` 는 apply(변경 없음) + 스모크 12/12 |
| `scale` (수동) | desired 2 → InService 2/2, 스모크 12/12 |

Floci 특이사항과 해결책은 [docs/troubleshooting.md](docs/troubleshooting.md) 에 정리했습니다.
