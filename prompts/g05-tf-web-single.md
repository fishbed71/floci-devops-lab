---
name: tf-web-single
description: EC2 1대 + user_data 로 웹서버 띄우기 (M4 단일 인스턴스 실습)
module: M4
---

# 단일 EC2 웹서버 생성

## 사용 시점

M4 오후. ASG 로 넘어가기 전에 "인스턴스 = 컨테이너" 와 user_data 동작을 눈으로 확인할 때.
M7 에서 이 코드는 `/tf-web-asg` 결과물로 대체한다.

## 프롬프트

```text
infra/envs/dev/web_single.tf 에 실습용 EC2 웹서버 1대를 만들어줘.

- aws_instance
  - ami = "ami-amazonlinux2023" (Floci 별칭 AMI → amazonlinux:2023 컨테이너)
  - instance_type = var.web_instance_type (기본 t3.micro)
  - subnet = module.network.public_subnet_ids[0]
  - vpc_security_group_ids = [module.network.web_sg_id]
  - tags: Name, Role = "web"
  - user_data (heredoc):
      #!/bin/bash
      dnf install -y nginx
      nginx 설정에서 listen 을 8000 으로 바꾸고(80 은 IMDS 프록시가 점유)
      /usr/share/nginx/html/index.html 에 호스트명과 시각을 쓰고
      systemd 가 없으므로 `nginx` 명령으로 직접 기동
- output: instance_id, private_ip

Floci 특이사항을 주석으로 남겨줘
- user_data 는 running 후 약 1분 뒤 실행된다
- SG 에 CIDR 규칙이 있으면 Floci 로그에 "app port 8000 on host port 300xx" 가 찍히고
  그 포트로 브라우저 접속이 가능하다
```

## 검증 명령

```powershell
terraform -chdir=infra/envs/dev apply          # 사람이 직접
docker ps --filter "name=floci-aws-ec2"        # 인스턴스 = 컨테이너 확인
docker logs floci 2>&1 | Select-String "host port"
curl.exe -s http://localhost:30000/             # 로그에 나온 포트
docker exec floci-aws-ec2-<instance-id> cat /var/log/user-data.log
```

## 리뷰 체크리스트

- [ ] nginx 가 8000 에서 리슨하는가
- [ ] user_data 를 두 번 실행해도 오류가 없는가 (`nginx -s reload` 고려)
- [ ] 인스턴스를 stop/start 하면 포트 포워드가 사라진다는 점을 이해했는가
