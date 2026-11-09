---
name: gha-workflows
description: self-hosted Windows runner 용 CI/CD 워크플로 4종 생성
module: M9
---

# GitHub Actions 워크플로 생성

## 사용 시점

M9. self-hosted runner(M8)가 온라인이 된 뒤.

## 프롬프트

```text
.github/workflows 에 Windows self-hosted runner(라벨: self-hosted, Windows, floci)에서
도는 워크플로 4개를 만들어줘. Floci 는 같은 PC 의 localhost:4566 에 있다.

공통
- runs-on: [self-hosted, Windows, floci]
- defaults.run.shell: powershell (Windows PowerShell 5.1 은 항상 있음)
- env: AWS_ENDPOINT_URL=http://localhost:4566, AWS_DEFAULT_REGION=us-east-1,
       AWS_ACCESS_KEY_ID=test, AWS_SECRET_ACCESS_KEY=test, TF_IN_AUTOMATION=1
- 액션 버전 고정: actions/checkout@v4, actions/github-script@v7
- Windows runner 는 컨테이너 job·서비스 컨테이너를 못 쓰므로 모든 단계를 run 스텝으로
- terraform 을 쓰는 job 은 concurrency group "terraform-dev" (cancel-in-progress: false)
- 각 run 스텝 끝에 if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE } 로 실패를 전파

1) infra-ci.yml — pull_request (paths: infra/**, app/**)
   - fmt -check -recursive → init → validate → plan -no-color -out=tfplan
   - terraform show -no-color tfplan 결과를 PR 코멘트로 게시 (github-script, 6만 자에서 자르기)
   - permissions: contents read, pull-requests write

2) infra-cd.yml — workflow_dispatch 전용 (입력: confirm)
   - main 브랜치이고 confirm == "apply" 일 때만 job 실행 → 사람이 직접 돌리는 것이 승인 단계
     (Environment 의 Required reviewers 는 private 저장소에서 Free·Pro·Team 이 지원하지 않음)
   - init → plan -out=tfplan → apply tfplan
   - 끝나고 http://localhost:8080/health 를 최대 5분 폴링해 db=ok 확인

3) app-ci.yml — pull_request (paths: app/**)
   - docker build -t guestbook:${{ github.sha }} app
   - postgres:16-alpine 과 앱 컨테이너를 docker network 에 띄워 /health 스모크 테스트
   - 성공·실패와 관계없이 컨테이너·네트워크 정리 (if: always())

4) scale.yml — workflow_dispatch
   - 입력: desired_capacity (choice 1,2,3,4)
   - aws autoscaling set-desired-capacity 실행 후 InService 개수가 입력값이 될 때까지 대기
   - Terraform 은 ignore_changes 로 대수를 관리하지 않으므로 apply 하지 않는다
```

## 검증 명령

```powershell
git switch -c test/ci; # 아무 tf 파일 주석 수정
git push -u origin test/ci   # PR 생성 → plan 코멘트 확인
gh workflow run scale.yml -f desired_capacity=3
gh run watch
```

## 리뷰 체크리스트

- [ ] 저장소가 private 인가 (public + self-hosted runner = 외부 PR 이 내 PC 에서 코드 실행)
- [ ] apply 는 main 에서만, 사람이 confirm=apply 로 실행할 때만 도는가
- [ ] plan 코멘트에 비밀값이 찍히지 않는가 (sensitive 처리)
