---
name: tf-db
description: RDS PostgreSQL 과 접속 정보를 담은 Secrets Manager 비밀 생성
module: M5
---

# db 모듈 생성

## 사용 시점

M5. 웹앱이 쓸 PostgreSQL 이 필요할 때.

## 프롬프트

```text
infra/modules/db 모듈을 만들고 infra/envs/dev/main.tf 에서 호출해줘.

리소스
- random_password (length 24, special = false — URL·셸 이스케이프 문제 방지)
- aws_db_subnet_group (프라이빗 서브넷 2개)
- aws_db_instance
  - engine postgres, engine_version "16"
  - instance_class = var.instance_class (기본 db.t3.micro)  ← 수직 스케일 실습 대상
  - allocated_storage = var.allocated_storage (기본 20)
  - db_name guestbook, username app, password = random_password
  - vpc_security_group_ids = [db SG], publicly_accessible = false
  - skip_final_snapshot = true, apply_immediately = true (실습용)
- aws_secretsmanager_secret (recovery_window_in_days = 0, 실습에서 바로 재생성 가능하게)
- aws_secretsmanager_secret_version: JSON {host, port, dbname, username, password}

출력: address, port, secret_arn, identifier

제약
- 비밀번호를 output 이나 tfvars 에 노출하지 말 것
- Floci 는 postgres:16-alpine 컨테이너를 실제로 띄운다.
  호스트에서는 localhost:<port>(7001~), EC2 컨테이너 안에서는 address:port 로 접속된다는 주석
```

## 검증 명령

```powershell
terraform -chdir=infra/envs/dev apply      # 사람이 직접
aws secretsmanager get-secret-value --secret-id guestbook-dev/db --query SecretString
docker run --rm -it --network host postgres:16-alpine psql "postgresql://app:<비밀번호>@localhost:7001/guestbook"
```

## 리뷰 체크리스트

- [ ] `terraform output` 에 비밀번호가 보이지 않는가
- [ ] DB SG 가 웹 SG 에서만 5432 를 허용하는가
- [ ] `instance_class` 를 바꿨을 때 plan 이 replace 가 아니라 update 인가
