---
name: app-docker
description: 웹앱 Dockerfile 과 로컬 개발용 compose.dev.yaml 생성
module: M2
---

# 웹앱 Dockerfile · compose.dev.yaml 생성

## 사용 시점

M2. `app/app.py` 를 로컬 Docker 로 실행·테스트하고, CI 에서 이미지를 빌드할 때.

## 프롬프트

```text
app/app.py (파이썬 표준 라이브러리 http.server + psycopg2 + boto3 방명록 앱)를 위한
Docker 파일을 만들어줘.

1) app/requirements.txt
   - psycopg2-binary, boto3 를 정확한 버전으로 고정

2) app/Dockerfile
   - 베이스: python:3.13-slim (태그 고정)
   - 레이어 캐시를 위해 requirements.txt 먼저 복사 후 pip install --no-cache-dir
   - 비루트 사용자(uid 10001)로 실행
   - PORT=8000, EXPOSE 8000
   - HEALTHCHECK: 파이썬 urllib 으로 http://127.0.0.1:8000/health 호출 (curl 설치 금지)
   - PYTHONUNBUFFERED=1

3) app/compose.dev.yaml (Floci 없이 앱 + PostgreSQL 만)
   - app: build ., 8000:8000, DB_HOST=db 등 환경변수, db 가 healthy 일 때 시작
   - db: postgres:16-alpine, pg_isready 헬스체크
   - 개발용 비밀번호는 이 파일에만, 실제 배포에서는 쓰지 않는다는 주석

4) .dockerignore (__pycache__, .venv, *.pyc, compose 파일)

각 줄에 왜 그렇게 했는지 한국어 주석을 달아줘.
```

## 검증 명령

```powershell
docker compose -f app/compose.dev.yaml up --build -d
curl.exe -s http://localhost:8000/health    # "db": "ok" 확인
docker compose -f app/compose.dev.yaml down
```

## 리뷰 체크리스트

- [ ] 루트(root)로 실행되지 않는가 (`docker exec <id> id`)
- [ ] 이미지 크기가 200MB 안팎인가 (`docker images`)
- [ ] 코드만 바꿨을 때 pip install 레이어가 캐시되는가
- [ ] 비밀번호가 Dockerfile 에 들어가지 않았는가
