---
name: tf-network
description: VPC·서브넷·라우팅·보안 그룹 network 모듈 생성
module: M4
---

# network 모듈 생성

## 사용 시점

M4. 웹·DB 를 올릴 네트워크와 보안 그룹이 필요할 때.

## 프롬프트

```text
infra/modules/network 에 재사용 가능한 Terraform 모듈을 만들고
infra/envs/dev/main.tf 에서 호출해줘.

리소스
- aws_vpc (DNS 지원·호스트명 활성화), aws_internet_gateway
- 퍼블릭 서브넷 2개(map_public_ip_on_launch), 프라이빗 서브넷 2개
  CIDR 은 cidrsubnet() 으로 계산 (퍼블릭 netnum 0,1 / 프라이빗 100,101)
- 퍼블릭 라우트 테이블 + 0.0.0.0/0 → IGW, 서브넷 연결
- 보안 그룹 3개
  - alb: var.alb_listener_port(기본 8080) 를 0.0.0.0/0 에서 허용
  - web: var.app_port(기본 8000) 를 alb SG 에서 허용
         + var.expose_web_to_host 가 true 면 같은 포트를 0.0.0.0/0 에서 허용
           (Floci 는 CIDR 규칙이 있는 포트를 localhost:300xx 로 노출함. 디버그용)
  - db: 5432 를 web SG 에서 허용
  - 규칙은 aws_vpc_security_group_ingress_rule / egress_rule 리소스로 분리

입력 변수: name, cidr(기본 10.10.0.0/16), azs, alb_listener_port, app_port, expose_web_to_host
출력: vpc_id, public_subnet_ids, private_subnet_ids, alb_sg_id, web_sg_id, db_sg_id

주의
- 앱 포트는 80 이 아니라 8000 이다. Floci EC2 컨테이너 안에서 IMDS 프록시가
  169.254.169.254:80 을 점유해 0.0.0.0:80 바인드가 실패한다.
- 모든 변수에 description 을 한국어로 달아줘.
```

## 검증 명령

```powershell
terraform -chdir=infra/envs/dev plan
aws ec2 describe-vpcs --query "Vpcs[].{id:VpcId,cidr:CidrBlock}"
aws ec2 describe-security-groups --query "SecurityGroups[].GroupName"
```

## 리뷰 체크리스트

- [ ] DB 보안 그룹이 0.0.0.0/0 을 허용하지 않는가
- [ ] 서브넷 CIDR 이 겹치지 않는가
- [ ] apply 직후 plan 이 `No changes` 인가 (드리프트 없음)
