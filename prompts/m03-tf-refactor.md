---
name: tf-refactor
description: 리소스를 모듈로 옮기거나 이름을 바꿀 때 moved 블록으로 재생성 없이 리팩터링
module: M4, M7
---

# Terraform 리팩터링

## 사용 시점

루트에 있던 리소스를 모듈로 옮기거나, 리소스 이름·count/for_each 구조를 바꿀 때.
그냥 옮기면 Terraform 은 "삭제 후 생성"으로 계획한다.

## 프롬프트

```text
<무엇을 어디로 옮길지 설명. 예: web_single.tf 의 aws_instance.web 를 modules/web 로>

조건
- 실제 리소스가 재생성되지 않도록 moved { from = ..., to = ... } 블록을 함께 작성
- 리팩터링 전후 terraform plan 결과를 비교해 "0 to add, 0 to destroy" 가 되는지 확인
  (변경이 남으면 그 이유를 설명)
- 변수·출력 이름은 기존 호출부가 깨지지 않게 유지하거나, 바뀌면 모든 참조를 함께 수정
- 모듈 README 에 입력·출력 표를 추가
```

## 검증 명령

```powershell
terraform -chdir=infra/envs/dev plan    # 0 to add, 0 to destroy 기대
terraform -chdir=infra/envs/dev state list
```

## 리뷰 체크리스트

- [ ] plan 에 destroy 가 없는가
- [ ] moved 블록은 한동안 남겨두고, 모든 환경에 적용된 뒤 지운다는 주석이 있는가
