---
name: real-aws-diff
description: 같은 Terraform 코드를 실제 AWS 로 옮길 때 바꿀 점을 REAL_AWS.md 로 정리
module: M10
---

# 실제 AWS 이전 분석

## 사용 시점

캡스톤 가산점 과제. 실제 배포는 하지 않고 문서만 만든다.

## 프롬프트

```text
이 저장소의 Terraform·워크플로를 실제 AWS 계정에 배포한다고 가정하고,
바꿔야 할 점을 REAL_AWS.md 로 정리해줘. 실제 AWS 에 어떤 요청도 보내지 마.

항목별로 "현재(Floci) | 실제 AWS | 바꿀 파일:줄 | 이유" 표
- provider: test 자격 증명·endpoints·skip_* 제거, 프로필 또는 OIDC
- backend: 실제 S3 버킷, 암호화, 버전 관리
- AMI: ami-amazonlinux2023 별칭 → aws_ami data source
- 앱 포트: 8000 유지 여부 (실제 EC2 에서는 80 사용 가능)
- user_data: systemd 경로가 쓰임, 인스턴스 프로파일(IAM 역할)로 Secrets Manager 읽기 권한 필요
- 네트워크: 프라이빗 서브넷 + NAT 게이트웨이, expose_web_to_host 제거, ALB 리스너 80/443 + ACM
- CI/CD: self-hosted runner → GitHub 호스티드 runner + OIDC 로 AWS 역할 가정
- 비용: NAT, ALB, RDS 의 시간당 비용 주의 (금액은 공식 가격 페이지 링크로)
마지막에 "로컬에서 plan 이 깨끗해도 실제 AWS 에서 실패할 수 있는 이유" 를 3줄로.
```

## 리뷰 체크리스트

- [ ] 실제 AWS 호출이나 자격 증명 사용이 없었는가
- [ ] 금액을 추측으로 적지 않았는가
