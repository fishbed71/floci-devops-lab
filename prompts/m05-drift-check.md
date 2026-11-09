---
name: drift-check
description: 코드와 실제 리소스의 차이(드리프트)를 찾아 원인별로 정리
module: M7, M9
---

# 드리프트 점검

## 사용 시점

누군가 콘솔·CLI 로 리소스를 직접 바꿨을 때, 또는 아무것도 안 바꿨는데 plan 에 변경이 뜰 때.

## 프롬프트

```text
infra/envs/dev 에서 terraform plan -refresh-only -no-color 와 terraform plan -no-color 를 실행하고
드리프트를 정리해줘. apply 는 하지 마.

표: 리소스 | 코드 값 | 실제 값 | 원인 추정 | 조치
원인 분류
- 사람이 CLI/콘솔로 바꿈 → 코드로 되돌릴지, 코드를 실제에 맞출지 제안
- 의도된 외부 관리 (예: ASG desired_capacity) → ignore_changes 가 있는지 확인
- 에뮬레이터·provider 표현 차이 (예: SG ID 앞에 계정 ID 가 붙음) → AGENTS.md 의 알려진 동작과 대조
조치마다 실행할 명령이나 코드 diff 를 붙여줘.
```

## 리뷰 체크리스트

- [ ] 드리프트를 무조건 apply 로 덮어쓰자고 하지 않았는가
- [ ] 영구 드리프트(매번 뜨는 변경)와 일회성 드리프트를 구분했는가
