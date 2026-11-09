---
name: floci-compose
description: Floci 로컬 AWS 를 띄우는 compose.yaml 생성
module: M1
---

# Floci compose.yaml 생성

## 사용 시점

M1. 저장소에 아직 `compose.yaml` 이 없을 때, 또는 노출 포트를 바꿔야 할 때.

## 프롬프트

```text
Windows 11 + Docker Desktop(WSL2) 환경에서 Floci(로컬 AWS 에뮬레이터, 이미지 floci/floci)를
띄우는 compose.yaml 을 저장소 루트에 만들어줘.

요구사항
- 이미지 태그는 floci/floci:2.4.0 으로 고정 (latest 금지)
- container_name: floci
- 포트: 4566(AWS API), 8080(ALB HTTP 리스너), 7001-7020(RDS 프록시)
- 환경변수
  - FLOCI_NETWORK_SECURITY_GROUP_ENFORCEMENT_ENABLED=false
    (보안 그룹 CIDR 규칙의 포트를 localhost:300xx 로 노출하기 위해)
  - FLOCI_SERVICES_RDS_PROXY_MAX_PORT=7020 (노출 포트 범위와 일치)
- 볼륨
  - /var/run/docker.sock:/var/run/docker.sock (EC2·RDS 를 실제 컨테이너로 띄우기 위해)
  - ./data:/app/data (재시작해도 리소스·state 유지)
- 각 설정 옆에 한국어 주석으로 이유를 적어줘
- data/ 를 .gitignore 에 추가해줘

마지막에 실행·확인 명령(PowerShell)을 알려줘.
```

## 검증 명령

```powershell
docker compose up -d
docker logs floci --tail 5          # "Ready." 확인
curl.exe -s http://localhost:4566/_floci/health
aws s3 mb s3://hello                # AWS_ENDPOINT_URL 이 설정돼 있어야 함
```

## 리뷰 체크리스트

- [ ] 이미지 태그가 고정돼 있는가
- [ ] docker.sock 이 마운트됐는가 (없으면 EC2·RDS 가 뜨지 않음)
- [ ] 8080, 7001~ 포트가 노출됐는가
- [ ] `data/` 가 git 에서 제외됐는가
