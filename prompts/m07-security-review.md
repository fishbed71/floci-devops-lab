---
name: security-review
description: 비밀값 노출, 보안 그룹, IAM, self-hosted runner 보안 점검
module: M5, M8, M10
---

# 보안 리뷰

## 사용 시점

캡스톤 제출 전, 또는 워크플로·보안 그룹을 바꾼 PR 에서.

## 프롬프트

```text
저장소 전체를 보안 관점에서 리뷰해줘. 코드는 고치지 말고 보고서만.

1. 비밀값
   - git grep 으로 password, secret, token, AKIA, BEGIN .* PRIVATE KEY 검색
   - tfvars, 워크플로, Dockerfile, user_data, terraform output 에 평문 비밀번호가 있는지
   - terraform.tfstate 는 비밀번호를 평문으로 담는다는 점과 state 버킷 접근 통제 설명
2. 네트워크
   - 0.0.0.0/0 인그레스 규칙 목록과 각각의 필요성 (expose_web_to_host 는 Floci 디버그 전용)
   - DB 가 퍼블릭으로 열려 있지 않은지
3. CI/CD
   - 저장소 공개 여부와 self-hosted runner 위험 (fork PR 이 내 PC 에서 코드 실행)
   - pull_request_target 사용 여부, permissions 최소화, 액션 버전 고정
   - apply 가 사람의 수동 실행(confirm=apply) 뒤에만 도는지
4. 실제 AWS 로 옮길 때 반드시 바꿔야 할 항목

출력: 심각도(높음/중간/낮음) | 위치(파일:줄) | 문제 | 권장 조치 표
```

## 리뷰 체크리스트

- [ ] "Floci 라서 괜찮은 것"과 "실제 AWS 에서 위험한 것"을 구분했는가
