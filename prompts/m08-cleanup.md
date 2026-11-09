---
name: cleanup
description: destroy 전 영향 확인과 destroy 후 남은 리소스·컨테이너 점검
module: 전체
---

# 정리 (destroy)

## 사용 시점

실습을 마칠 때, 노트북 메모리가 부족할 때, 처음부터 다시 하고 싶을 때.

## 프롬프트

```text
실습 리소스를 정리하려고 해. 직접 destroy 하지 말고 아래를 해줘.

1. terraform -chdir=infra/envs/dev plan -destroy 를 실행해 지워질 리소스 수와 종류를 요약
2. 지우기 전에 보존할 것 확인 (방명록 데이터를 남기려면 pg_dump 명령 제시)
3. 내가 실행할 destroy 명령을 안내
4. destroy 후 점검 명령을 실행해 남은 것을 보고
   - docker ps -a --filter label=io.floci --format "{{.Names}}"
     (floci-aws-ec2-volume-helper 는 Floci 공용 컨테이너라 남아도 정상)
   - aws ec2 describe-instances --query "Reservations[].Instances[].State.Name"
   - aws rds describe-db-instances --query "DBInstances[].DBInstanceIdentifier"
   - aws s3 ls s3://tfstate/dev/   (state 는 남는 것이 정상)
5. Floci 까지 완전히 초기화하는 방법(docker compose down, data 폴더 삭제)과 그 결과
   (state 버킷도 사라지므로 bootstrap 부터 다시)를 설명
```

## 리뷰 체크리스트

- [ ] `docker compose down -v` 나 data 삭제를 묻지 않고 실행하지 않았는가
