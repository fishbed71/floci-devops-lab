---
name: tf-web-asg
description: Launch Template + Auto Scaling Group + ALB 웹 계층 모듈 생성
module: M7
---

# web 모듈 (ASG + ALB) 생성

## 사용 시점

M7. 단일 인스턴스를 확장 가능한 웹 계층으로 바꿀 때. 캡스톤의 핵심 모듈.

## 프롬프트

```text
infra/modules/web 모듈을 만들어 단일 EC2(web_single.tf)를 대체해줘.

리소스
- aws_launch_template
  - image_id 기본 "ami-amazonlinux2023", instance_type = var.instance_type
  - user_data = base64encode(templatefile("templates/user-data.sh.tftpl", {...}))
    템플릿 변수: app_py_b64(filebase64(app.py)), app_version, db_secret_arn, region, app_port
  - update_default_version = true
  - tag_specifications(instance): Name, Role = "web", AppVersion
- aws_lb (application, 퍼블릭 서브넷, alb SG)
- aws_lb_target_group
  - port = var.app_port(8000), health_check path /health
  - name_prefix = "web-" + lifecycle create_before_destroy
    (포트가 바뀌어 교체될 때 리스너가 사용 중이라 삭제가 실패하는 문제 방지)
- aws_lb_listener: port = var.alb_listener_port(8080), forward
- aws_autoscaling_group
  - min/max/desired 변수, target_group_arns, launch_template version = latest_version
  - health_check_type = "EC2", grace 120 (Floci user_data 가 기동 1분 뒤 실행되므로)
  - instance_refresh { strategy = "Rolling", min_healthy_percentage = 50 }
  - lifecycle ignore_changes = [desired_capacity]
    (scale 워크플로가 바꾼 대수를 다음 apply 가 되돌리지 않게)

app_version 은 env 쪽에서 app.py 내용 해시(filesha256 앞 8자리)로 계산해 넘겨줘.
→ 앱 코드가 바뀔 때만 launch template 이 바뀌고 instance refresh 가 일어난다.

출력: alb_dns_name, asg_name, launch_template_version, target_group_arn
env 출력: app_url = "http://localhost:8080"
```

## 검증 명령

```powershell
terraform -chdir=infra/envs/dev apply                 # 사람이 직접
1..6 | % { curl.exe -s http://localhost:8080/health; "" }   # host 값이 번갈아 나오는지
aws autoscaling set-desired-capacity --auto-scaling-group-name guestbook-dev-web --desired-capacity 4
terraform -chdir=infra/envs/dev plan                  # No changes 여야 함
```

## 리뷰 체크리스트

- [ ] 응답의 host 가 인스턴스 수만큼 번갈아 나오는가 (라운드로빈)
- [ ] 컨테이너 하나를 `docker rm -f` 하면 ASG 가 새로 띄우는가
- [ ] set-desired-capacity 후 plan 이 대수를 되돌리려 하지 않는가
