@AGENTS.md

## Claude Code 전용

- 슬래시 커맨드는 `.claude/commands/` 에 있다. 원본은 `prompts/` 이며 `scripts/sync-agent-prompts.ps1` 로 생성한다. 커맨드 파일을 직접 고치지 말고 `prompts/` 를 고친 뒤 스크립트를 다시 실행한다.
- 큰 변경은 plan 모드에서 계획을 먼저 보여주고 승인받은 뒤 진행한다.
- `.claude/settings.json` 이 `terraform apply`·`destroy` 실행을 막는다. 막혔다면 우회하지 말고 사용자에게 명령을 안내한다.
