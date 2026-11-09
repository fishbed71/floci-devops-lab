---
name: docker-review
description: Dockerfile·compose 파일의 보안·버전 고정·이미지 크기·캐시 점검과 개선
module: M1, M2
---

# Docker 파일 리뷰

## 사용 시점

`compose.yaml`, `app/Dockerfile`, `app/compose.dev.yaml` 을 만들거나 바꾼 뒤.

## 프롬프트

```text
compose.yaml, app/Dockerfile, app/compose.dev.yaml, app/.dockerignore 를 리뷰하고 개선안을 제시해줘.

점검 항목
1. 버전 고정: latest 태그, 범위 지정 없는 pip 패키지
2. 보안: 루트 실행, 이미지·compose 에 박힌 비밀번호, 불필요한 포트 노출, docker.sock 마운트의 위험 설명
3. 크기·속도: 레이어 순서(의존성 먼저), 캐시 무효화, 불필요한 파일 COPY, --no-cache-dir
4. 운영: HEALTHCHECK, depends_on condition, 재시작 정책, 로그
5. Floci 전용: 4566/8080/7001~ 포트, FLOCI_* 환경변수, ./data 볼륨

출력
- 표: 파일 | 줄 | 문제 | 심각도 | 수정안
- 수정 diff (적용은 승인 뒤)
- 수정 전후 이미지 크기를 비교할 명령
```

## 검증 명령

```powershell
docker build -t guestbook:review app
docker images guestbook
docker run --rm guestbook:review id     # uid=10001 기대
```

## 리뷰 체크리스트

- [ ] docker.sock 마운트가 "호스트 Docker 전체 권한"이라는 설명이 있는가
- [ ] 개선안이 실제로 빌드되는가
