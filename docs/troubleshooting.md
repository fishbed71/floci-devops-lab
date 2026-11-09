# 트러블슈팅과 Floci 특이사항

2026-11-09, Floci 2.4.0 + Docker Desktop 29.7.2 (Windows 11) 에서 실제로 겪고 해결한 내용입니다.

## 실습 중 확인된 동작

| 현상 | 원인 | 이 저장소의 해결 |
| --- | --- | --- |
| 앱이 `OSError: [Errno 98] Address already in use` 로 죽음 | EC2 컨테이너 안에서 IMDS 프록시(socat)가 `169.254.169.254:80` 을 점유. `0.0.0.0:80` 바인드 불가 | 앱 포트 8000 (`app_port` 변수), 타깃 그룹·SG 도 8000 |
| 인스턴스가 running 인데 앱이 응답 없음 | user_data 는 running 후 약 1분 뒤(IMDS·sshd 설정 후) 실행 | ASG `health_check_type = "EC2"`, grace 120초. 스모크 테스트는 최대 5분 대기 |
| plan 할 때마다 SG 규칙 `referenced_security_group_id` 변경 | provider 에 `skip_requesting_account_id = true` 가 있으면 계정 ID 를 몰라 SG 를 "다른 계정"으로 표시 | 그 옵션 제거 (Floci STS 가 `000000000000` 반환) |
| 위 옵션을 지운 뒤 `Unexpected Identity Change` | 옵션 없이 만든 state 와 리소스 identity 가 다름 | 새로 만드는 환경은 해당 없음. 기존 환경은 `destroy -refresh=false` 후 재생성 |
| 타깃 그룹 포트 변경 시 `ResourceInUse` | 고정 이름 + 리스너가 사용 중이라 삭제 먼저 불가 (실제 AWS 도 동일) | `name_prefix` + `create_before_destroy` |
| `ssm send-command --targets Key=tag:Role,Values=web` 실패 | Floci 는 태그 대상 지정을 지원하지 않음 (`InvalidInstanceId`) | ASG 인스턴스 ID 를 `--instance-ids` 로 전달 (`provision/ssm-run.ps1`) |
| instance refresh 중 1~2분 응답 없음 | Floci 는 `min_healthy_percentage` 와 관계없이 전체를 동시에 교체 | 수업에서 "실제 AWS 는 롤링" 으로 설명. 무중단이 필요하면 SSM 배포 사용 |
| 스케일 아웃 직후 일부 요청 502 | 새 인스턴스가 타깃에 등록됐지만 user_data 실행 전 | 1~2분 뒤 정상. 스모크 테스트로 확인 |
| DB `instance_class` 변경이 컨테이너에 반영 안 됨 | Floci RDS 는 클래스를 메타데이터로만 저장 (컨테이너 재시작·자원 제한 없음) | 수직 스케일 관찰은 웹 인스턴스 타입으로 (t3.micro 1 GiB → t3.medium 4 GiB) |
| `aws ec2 run-instances --user-data` 스크립트가 안 돌아감 | AWS CLI v2 가 user-data 를 자동으로 base64 인코딩. 직접 인코딩하면 이중 인코딩 | CLI 에는 평문 스크립트를 넘긴다. Terraform 은 `base64encode()` 사용 |
| `docker exec ... cat /tmp/x` 가 Windows 경로로 바뀜 (Git Bash) | Git Bash 경로 자동 변환 | PowerShell 사용, 또는 `MSYS_NO_PATHCONV=1` |

## 포트 정리

| 포트 | 무엇 | 어디서 열리나 |
| --- | --- | --- |
| 4566 | AWS API 전체 | Floci 컨테이너 (`compose.yaml`) |
| 8080 | ALB HTTP 리스너 | Floci 컨테이너 안 → `compose.yaml` 에 노출 필요 |
| 7001~7020 | RDS 프록시 (호스트 → DB) | Floci 컨테이너 → `compose.yaml` 에 노출 |
| 30000~ | 웹 인스턴스 앱 포트 직접 접속 | Floci 가 socat 사이드카로 자동 노출 (SG 에 CIDR 규칙이 있을 때) |
| 2200~ | 인스턴스 SSH | Floci 가 자동 노출 (키페어 지정 시 키 주입) |

## 유용한 명령

```powershell
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
docker logs floci --tail 50
docker logs floci 2>&1 | Select-String "host port"              # 인스턴스별 노출 포트
docker exec floci-aws-ec2-<instance-id> tail -20 /var/log/user-data.log
docker exec floci-aws-ec2-<instance-id> tail -20 /var/log/guestbook.log
docker inspect <컨테이너> --format "{{.HostConfig.NanoCpus}} {{.HostConfig.Memory}}"
aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[0].Instances[].[InstanceId,LifecycleState]"
aws elbv2 describe-target-health --target-group-arn <arn>
```

## 완전 초기화

```powershell
terraform -chdir=infra/envs/dev destroy
docker compose down
Remove-Item -Recurse -Force .\data          # Floci 영속 데이터 (state 버킷 포함) 삭제
docker compose up -d
.\scripts\bootstrap-state.ps1
Remove-Item -Recurse -Force infra\envs\dev\.terraform
terraform -chdir=infra/envs/dev init
```
