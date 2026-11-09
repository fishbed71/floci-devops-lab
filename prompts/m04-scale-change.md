---
name: scale-change
description: 웹·DB 의 수평/수직 스케일 변경과 영향 분석, PR 설명 작성
module: M7, M9
---

# 스케일 변경

## 사용 시점

웹서버 대수, 인스턴스 타입, DB 클래스·스토리지를 바꿀 때.

## 프롬프트

```text
다음 스케일 변경을 해줘: <예: 웹서버 t3.micro → t3.medium, DB db.t3.micro → db.t3.small>

규칙
- 수평 확장(대수)은 Terraform 이 아니라 scale 워크플로(set-desired-capacity)로 한다.
  ASG 는 ignore_changes = [desired_capacity] 이므로 tfvars 의 desired 값은 최초 생성에만 쓰인다.
  대수 변경 요청이면 코드를 바꾸지 말고 실행할 명령/워크플로를 안내해.
- 수직 확장(타입·클래스·스토리지)은 infra/envs/dev/terraform.tfvars 만 수정
- 변경 후 plan 을 실행해 영향을 정리
  - 웹: launch template 새 버전 → instance refresh (인스턴스 교체, 다운타임 여부)
  - DB: update in-place 인지 replace 인지, 재시작 여부
- 수정 내용으로 PR 제목과 본문을 작성 (변경 이유, 영향, 롤백 방법)

참고: Floci 는 인스턴스 타입 카탈로그의 vCPU·메모리로 컨테이너를 제한한다.
확인: docker inspect <컨테이너> --format "{{.HostConfig.NanoCpus}} {{.HostConfig.Memory}}"
```

## 리뷰 체크리스트

- [ ] 대수 변경을 tfvars 로 하려고 하지 않았는가
- [ ] PR 본문에 롤백 방법(이전 값으로 되돌리는 PR)이 있는가
