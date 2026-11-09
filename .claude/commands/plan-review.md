---
description: terraform plan 결과를 위험도별로 검토하고 apply 해도 되는지 판단
argument-hint: [추가 요구사항]
---
<!-- 자동 생성 파일. prompts/m01-plan-review.md 를 고친 뒤 scripts/sync-agent-prompts.ps1 을 다시 실행하세요. -->

@prompts/m01-plan-review.md

위 파일의 "프롬프트" 블록을 작업 지시로 삼아 수행하라.
- AGENTS.md 의 절대 규칙을 지킨다. terraform apply/destroy 는 실행하지 말고 명령만 안내한다.
- 끝나면 "리뷰 체크리스트"로 스스로 점검한 결과와 "검증 명령"을 보고한다.

추가 요구사항: $ARGUMENTS
