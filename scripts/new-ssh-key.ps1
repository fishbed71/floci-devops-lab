# M6(Ansible·SSH) 실습용 SSH 키를 만든다. 공개키가 있으면 Terraform 이 키페어로 등록한다.
# 키는 provision/keys/ 에 생기며 git 에서 제외된다.
# 사용: .\scripts\new-ssh-key.ps1

$root = Split-Path -Parent $PSScriptRoot
$dir  = Join-Path $root 'provision\keys'
$key  = Join-Path $dir 'lab_ed25519'

if (Test-Path $key) {
    Write-Host "이미 있습니다: $key"
    exit 0
}

New-Item -ItemType Directory -Force -Path $dir | Out-Null
& ssh-keygen -t ed25519 -f $key -N '""' -C 'floci-lab' -q
if ($LASTEXITCODE -ne 0) { Write-Error 'ssh-keygen 실패 (Windows 선택적 기능 OpenSSH 클라이언트 확인)'; exit 1 }

Write-Host "만들었습니다: $key(.pub)"
Write-Host '다음 terraform apply 때 키페어가 등록되고, 새 인스턴스부터 적용됩니다.'
Write-Host '접속: docker ps 로 SSH 호스트 포트(2200~) 확인 후  ssh -i provision\keys\lab_ed25519 -p 2200 root@localhost'
