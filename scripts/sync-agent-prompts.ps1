# prompts/*.md (README 제외) 를 원본으로 에이전트용 파일을 생성한다.
#   .claude/commands/<name>.md   → Claude Code 슬래시 커맨드 (/name)
#   .agent/workflows/<name>.md   → Google Antigravity 워크플로 (/name)
#   .agent/rules/guardrails.md   → AGENTS.md 사본 (Antigravity 워크스페이스 규칙)
# 사용: powershell -ExecutionPolicy Bypass -File scripts/sync-agent-prompts.ps1

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$utf8 = New-Object System.Text.UTF8Encoding($false)   # BOM 없는 UTF-8

$claudeDir = Join-Path $root '.claude\commands'
$agentDir  = Join-Path $root '.agent\workflows'
$rulesDir  = Join-Path $root '.agent\rules'
foreach ($dir in @($claudeDir, $agentDir, $rulesDir)) {
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
}

# 이전에 생성한 파일 정리 (원본에서 지운 프롬프트가 남지 않도록)
Get-ChildItem $claudeDir -Filter '*.md' | Remove-Item -Force
Get-ChildItem $agentDir  -Filter '*.md' | Remove-Item -Force

$prompts = Get-ChildItem (Join-Path $root 'prompts') -Filter '*.md' |
    Where-Object { $_.Name -ne 'README.md' } |
    Sort-Object Name

foreach ($file in $prompts) {
    $text = [IO.File]::ReadAllText($file.FullName, $utf8)
    $fm = [regex]::Match($text, '(?s)^---\r?\n(.*?)\r?\n---')
    if (-not $fm.Success) { throw "frontmatter 가 없습니다: $($file.Name)" }

    $name = [regex]::Match($fm.Groups[1].Value, '(?m)^name:\s*(.+?)\s*$').Groups[1].Value
    $desc = [regex]::Match($fm.Groups[1].Value, '(?m)^description:\s*(.+?)\s*$').Groups[1].Value
    if (-not $name -or -not $desc) { throw "name/description 이 없습니다: $($file.Name)" }
    $rel = "prompts/$($file.Name)"

    $claude = @"
---
description: $desc
argument-hint: [추가 요구사항]
---
<!-- 자동 생성 파일. $rel 를 고친 뒤 scripts/sync-agent-prompts.ps1 을 다시 실행하세요. -->

@$rel

위 파일의 "프롬프트" 블록을 작업 지시로 삼아 수행하라.
- AGENTS.md 의 절대 규칙을 지킨다. terraform apply/destroy 는 실행하지 말고 명령만 안내한다.
- 끝나면 "리뷰 체크리스트"로 스스로 점검한 결과와 "검증 명령"을 보고한다.

추가 요구사항: `$ARGUMENTS
"@

    $agent = @"
---
description: $desc
---
<!-- 자동 생성 파일. $rel 를 고친 뒤 scripts/sync-agent-prompts.ps1 을 다시 실행하세요. -->

1. ``$rel`` 파일을 읽는다.
2. "프롬프트" 블록의 지시를 수행한다. 사용자가 덧붙인 요구사항이 있으면 함께 반영한다.
3. AGENTS.md 의 절대 규칙을 지킨다. ``terraform apply``, ``terraform destroy`` 는 실행하지 말고 명령만 안내한다.
4. "리뷰 체크리스트"로 결과를 점검하고 "검증 명령"을 사용자에게 안내한다.
"@

    [IO.File]::WriteAllText((Join-Path $claudeDir "$name.md"), $claude + "`n", $utf8)
    [IO.File]::WriteAllText((Join-Path $agentDir "$name.md"), $agent + "`n", $utf8)
    Write-Host ("  /{0,-16} <- {1}" -f $name, $rel)
}

# Antigravity 규칙: AGENTS.md 를 항상 적용되는 규칙으로 복사
$agents = [IO.File]::ReadAllText((Join-Path $root 'AGENTS.md'), $utf8)
$rule = "---`ntrigger: always_on`n---`n<!-- 자동 생성 파일. AGENTS.md 를 고친 뒤 scripts/sync-agent-prompts.ps1 을 다시 실행하세요. -->`n`n" + $agents
[IO.File]::WriteAllText((Join-Path $rulesDir 'guardrails.md'), $rule, $utf8)

Write-Host "생성 완료: 커맨드·워크플로 $($prompts.Count)개, 규칙 1개"
