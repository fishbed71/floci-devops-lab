# Self-hosted runner 설치 (Windows 11)

GitHub 호스티드 runner 는 수강생 PC 의 `localhost:4566` 에 닿지 못합니다.
그래서 Floci 가 도는 같은 PC 에 runner 를 설치합니다.

## 1. 보안 원칙 먼저

- **저장소는 private 으로 유지합니다.** public 저장소에 self-hosted runner 를 붙이면
  누구나 fork 후 PR 을 열어 내 PC 에서 코드를 실행할 수 있습니다.
- runner 는 실습이 끝나면 중지하거나 저장소에서 제거합니다.

## 2. runner 내려받기와 등록

1. 저장소 **Settings → Actions → Runners → New self-hosted runner** 를 엽니다.
2. **Windows / x64** 를 고르면 나오는 명령을 PowerShell 에서 그대로 실행합니다
   (폴더 예: `C:\actions-runner`. 버전과 해시는 페이지에 나온 값을 씁니다).
3. `config.cmd` 단계에서 라벨을 추가합니다.

    ```powershell
    .\config.cmd --url https://github.com/<OWNER>/<REPO> --token <페이지의 토큰> --labels floci
    ```

    서비스로 실행할지 묻는 질문에는 **N** 을 답합니다 (아래 3 참고).

## 3. 실행 방식

수업에서는 **포그라운드 실행**을 권장합니다. 내 사용자 계정으로 돌기 때문에
Docker Desktop, Terraform, AWS CLI 의 PATH·권한 문제가 없습니다.

```powershell
cd C:\actions-runner
.\run.cmd          # 창을 닫으면 runner 도 멈춤
```

서비스로 상시 실행하려면 runner 서비스 계정을 **내 사용자 계정**으로 지정합니다.
기본 계정(NETWORK SERVICE)은 내 PATH 의 terraform·aws 를 못 찾고 Docker 권한도 없습니다.

```powershell
.\config.cmd --url https://github.com/<OWNER>/<REPO> --token <토큰> --labels floci `
  --runasservice --windowslogonaccount "$env:USERDOMAIN\$env:USERNAME"
```

## 4. 확인

- Settings → Actions → Runners 에서 상태가 **Idle**
- 라벨: `self-hosted`, `Windows`, `X64`, `floci`
- runner 를 실행한 터미널에서 아래가 모두 동작해야 합니다.

    ```powershell
    docker ps
    terraform version
    aws --version
    ```

## 5. 워크플로 사용

| 워크플로 | 트리거 | 하는 일 |
| --- | --- | --- |
| `infra-ci` | PR (infra/**, app/app.py) | fmt → validate → plan, PR 코멘트 |
| `app-ci` | PR (app/**) | 이미지 빌드 + PostgreSQL 과 스모크 테스트 |
| `infra-cd` | 수동 실행, confirm=`apply` | main 을 Floci 에 apply + 스모크 테스트 |
| `scale` | 수동 실행, 대수 1~4 | ASG desired capacity 변경 |

```powershell
gh workflow run infra-cd.yml -f confirm=apply
gh workflow run scale.yml -f desired_capacity=3
gh run watch
```

`infra-cd` 를 수동 실행으로 만든 이유: GitHub Environment 의 승인자(Required reviewers) 기능은
private 저장소에서 Free·Pro·Team 플랜이 지원하지 않습니다. 그래서 "사람이 직접 실행 + 확인 문구"를 승인 단계로 씁니다.

## 6. 자주 막히는 곳

| 증상 | 해결 |
| --- | --- |
| job 이 `Queued` 에서 멈춤 | runner 가 꺼져 있거나 `runs-on` 라벨(`floci`) 불일치 |
| `terraform : 용어가 ... 인식되지 않습니다` | 서비스 계정 PATH 문제 → 포그라운드 실행 또는 사용자 계정 서비스 |
| `error during connect ... docker` | Docker Desktop 미실행 |
| state 잠금 오류 | 다른 apply 가 진행 중. 워크플로는 `concurrency: terraform-dev` 로 직렬화됨 |
