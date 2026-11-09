# 바이브코딩 프롬프트 모음

Terraform·Docker·GitHub Actions 파일을 **만들고(생성)**, **고치고 지키는(관리)** 데 쓰는 프롬프트다.
수강생은 빈 저장소에서 이 프롬프트로 파일을 만들어 가고, 이 저장소의 완성 코드와 비교한다.

## 쓰는 방법

| 도구 | 실행 방법 |
| --- | --- |
| Claude Code | `/tf-network` 처럼 슬래시 커맨드로 실행. 뒤에 추가 요구사항을 붙일 수 있다: `/tf-network NAT 게이트웨이도 추가` |
| Google Antigravity | 에이전트 입력창에서 `/tf-network` 워크플로 실행, 또는 "prompts/g04-tf-network.md 를 수행해줘" |
| 그 밖의 도구 | 각 파일의 **프롬프트** 블록을 복사해 붙여넣기 |

슬래시 커맨드(`.claude/commands/`)와 Antigravity 워크플로(`.agent/workflows/`)는 이 폴더에서 생성된다.
프롬프트를 고친 뒤에는 다시 생성한다.

```powershell
powershell -ExecutionPolicy Bypass -File scripts/sync-agent-prompts.ps1
```

## 프롬프트 목록

### 생성 (g)

| 커맨드 | 파일 | 모듈 | 만드는 것 |
| --- | --- | --- | --- |
| `/floci-compose` | [g01](g01-floci-compose.md) | M1 | Floci 실행용 `compose.yaml` |
| `/app-docker` | [g02](g02-app-docker.md) | M2 | 웹앱 `Dockerfile`, 로컬 개발 `compose.dev.yaml` |
| `/tf-foundation` | [g03](g03-tf-foundation.md) | M3 | provider·backend·versions, state 버킷 부트스트랩 |
| `/tf-network` | [g04](g04-tf-network.md) | M4 | VPC·서브넷·보안 그룹 모듈 |
| `/tf-web-single` | [g05](g05-tf-web-single.md) | M4 | EC2 1대 + user_data 웹서버 |
| `/tf-db` | [g06](g06-tf-db.md) | M5 | RDS PostgreSQL + Secrets Manager |
| `/tf-web-asg` | [g07](g07-tf-web-asg.md) | M7 | Launch Template + ASG + ALB |
| `/provisioning` | [g08](g08-provisioning.md) | M6 | 멱등 user_data, SSM 배포 스크립트 |
| `/gha-workflows` | [g09](g09-gha-workflows.md) | M9 | CI/CD 워크플로 4종 |

### 관리 (m)

| 커맨드 | 파일 | 언제 |
| --- | --- | --- |
| `/plan-review` | [m01](m01-plan-review.md) | apply 전에 plan 결과를 위험도별로 검토 |
| `/diagnose` | [m02](m02-diagnose.md) | apply 실패, 앱 접속 불가 등 오류 원인 찾기 |
| `/tf-refactor` | [m03](m03-tf-refactor.md) | 리소스를 모듈로 옮기기, 이름 바꾸기(`moved` 블록) |
| `/scale-change` | [m04](m04-scale-change.md) | 대수·타입 변경과 PR 설명 작성 |
| `/drift-check` | [m05](m05-drift-check.md) | 코드와 실제 리소스의 차이 점검 |
| `/docker-review` | [m06](m06-docker-review.md) | Dockerfile·compose 보안·버전·크기 점검 |
| `/security-review` | [m07](m07-security-review.md) | 비밀값·보안 그룹·runner 보안 점검 |
| `/cleanup` | [m08](m08-cleanup.md) | destroy 전후 남은 리소스·컨테이너 점검 |
| `/real-aws-diff` | [m09](m09-real-aws-diff.md) | 같은 코드를 실제 AWS 로 옮길 때 바꿀 점 정리 |

## 좋은 프롬프트의 5요소

모든 프롬프트는 같은 뼈대를 따른다. 직접 프롬프트를 쓸 때도 이 순서를 지킨다.

1. **맥락**: 어떤 환경인가 (Floci, Windows 11, 기존 파일 경로)
2. **목표**: 무엇을 만들거나 바꾸는가 (파일 경로까지)
3. **제약**: 지켜야 할 규칙 (엔드포인트, 버전 고정, 비밀값 금지, Floci 특이사항)
4. **산출물 형식**: 파일 목록, 변수·출력 이름, 주석 언어
5. **검증**: 사람이 돌릴 명령과 기대 결과

## AI 결과물 리뷰 습관

- 생성된 리소스를 한 줄씩 설명할 수 없다면 머지하지 않는다.
- `plan` 의 `destroy`/`must be replaced` 줄은 반드시 이유를 확인한다.
- AI 가 틀린 곳과 고친 이유를 `AI_LOG.md` 에 남긴다 (평가 항목).
