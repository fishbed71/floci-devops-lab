---
name: plan-review
description: terraform plan 결과를 위험도별로 검토하고 apply 해도 되는지 판단
module: M3~M10
---

# plan 리뷰

## 사용 시점

`terraform apply` 직전, 또는 PR 에 달린 plan 코멘트를 읽을 때.

## 프롬프트

```text
infra/envs/dev 에서 terraform plan -no-color 를 실행하고 (이미 결과가 있으면 그 텍스트를 읽고)
아래 형식으로 검토해줘. apply 는 하지 마.

1. 한 줄 결론: "apply 해도 됨 / 확인 필요 / 하지 말 것" + 이유
2. 표: 리소스 주소 | 동작(create/update/replace/destroy) | 위험도(높음/중간/낮음) | 이유
   - replace·destroy 는 무엇이 교체를 유발했는지("# forces replacement" 속성) 명시
   - DB, 보안 그룹, 타깃 그룹, launch template 변경은 서비스 영향(다운타임, 데이터 손실)을 설명
3. 예상하지 못한 변경(코드를 안 바꿨는데 바뀌는 것 = 드리프트)이 있으면 별도로 표시
4. 위험을 줄이는 방법 (create_before_destroy, 순서 분리, 백업 등)
```

## 리뷰 체크리스트

- [ ] `aws_db_instance` 가 replace 로 나오면 데이터가 사라진다는 경고가 있는가
- [ ] 변경 개수(Plan: x to add, y to change, z to destroy)가 PR 의도와 맞는가
