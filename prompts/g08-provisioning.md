---
name: provisioning
description: 멱등 user_data 템플릿과 SSM Run Command 배포 스크립트 생성
module: M6
---

# 프로비저닝 스크립트 생성

## 사용 시점

M6. 서버 내부 구성(패키지·앱·설정)을 자동화할 때.
부팅 시 1회(user_data)와 운영 중 언제든(SSM Run Command) 두 경로를 모두 만든다.

## 프롬프트

```text
웹서버 프로비저닝을 두 가지 경로로 만들어줘.

1) infra/modules/web/templates/user-data.sh.tftpl (Terraform templatefile)
   - set -euo pipefail, 모든 출력은 /var/log/user-data.log 에 추가
   - dnf install -y -q python3 python3-psycopg2 python3-boto3
   - /opt/guestbook/app.py 를 base64 템플릿 변수에서 복원
   - /opt/guestbook/app.env 에 APP_VERSION, DB_SECRET_ARN, AWS_REGION, PORT
   - 기동
     - /run/systemd/system 이 있으면(실제 AWS) systemd 유닛 등록 후 restart
     - 없으면(Floci 컨테이너) pid 파일로 기존 프로세스 종료 후 nohup 백그라운드 실행
   - 두 번 실행해도 결과가 같아야 한다(멱등)
   - 템플릿 안의 셸 변수는 $${VAR} 로 이스케이프 (Terraform 보간과 충돌 방지)

2) provision/ssm-run.ps1 (PowerShell)
   - 파라미터: -AsgName (기본 guestbook-dev-web), -Command (기본: 앱 재시작)
   - ASG 의 인스턴스 ID 를 조회해 aws ssm send-command --instance-ids 로 실행
     (Floci 는 --targets Key=tag:... 를 지원하지 않음)
   - 완료를 기다린 뒤 인스턴스별 Status 와 StandardOutputContent 출력

3) (선택) provision/ansible/
   - inventory 예시: 각 인스턴스의 SSH 호스트 포트(2200~)를 docker ps 로 찾아 넣는 방법을 README 로
   - playbook: 패키지 설치와 app.env 갱신

주석은 한국어로.
```

## 검증 명령

```powershell
docker exec floci-aws-ec2-<id> bash /var/lib/user-data.sh   # 수동 재실행해도 성공해야 함
.\provision\ssm-run.ps1 -Command "curl -s localhost:8000/health"
```

## 리뷰 체크리스트

- [ ] 스크립트를 두 번 돌려도 프로세스가 두 개 뜨지 않는가
- [ ] 비밀번호가 user_data 에 들어가지 않고 Secrets Manager 에서 읽는가
- [ ] 실제 AWS(systemd) 경로도 문법이 맞는가
