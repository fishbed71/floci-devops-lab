---
name: diagnose
description: terraform 오류, 앱 접속 불가, 워크플로 실패의 원인 진단
module: 전체
---

# 오류 진단

## 사용 시점

apply 실패, `localhost:8080` 응답 없음, runner job 실패 등 막혔을 때.

## 프롬프트

```text
아래 증상의 원인을 찾아줘. 추측으로 코드를 고치지 말고, 먼저 근거를 모아 가설을 세워.

증상: <오류 메시지나 현상을 그대로 붙여넣기>

진단 순서
1. 증상을 재현하는 가장 작은 명령을 제시
2. 근거 수집 (읽기 전용 명령만 실행)
   - docker ps --format "{{.Names}}\t{{.Status}}\t{{.Ports}}"
   - docker logs floci --tail 100
   - docker exec <인스턴스 컨테이너> tail -50 /var/log/user-data.log /var/log/guestbook.log
   - terraform -chdir=infra/envs/dev plan
   - aws autoscaling describe-auto-scaling-groups / elbv2 describe-target-health
3. AGENTS.md 의 "Floci 에서 확인된 동작" 목록과 대조
4. 가설 1~3개를 가능성 순으로, 각각 확인 방법과 함께
5. 원인이 확정되면 최소 수정안 diff 를 제시 (적용은 내가 승인한 뒤)

자주 나오는 원인
- endpoints 누락 → 실제 AWS 로 요청 (InvalidClientTokenId)
- 앱이 80 포트 → IMDS 프록시와 충돌 (Address already in use)
- user_data 가 아직 실행 전 (기동 후 약 1분)
- 타깃 그룹 교체 시 ResourceInUse → create_before_destroy 누락
- SG 참조 규칙 영구 드리프트 → skip_requesting_account_id 사용
```

## 리뷰 체크리스트

- [ ] 근거(로그 줄, 명령 결과) 없이 결론을 내리지 않았는가
- [ ] 수정이 증상 하나만 고치는 최소 변경인가
