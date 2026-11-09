# 웹 계층: Launch Template + Auto Scaling Group + ALB
# 앱 코드가 바뀌면 launch template 새 버전 → instance refresh 로 롤링 교체된다.

locals {
  user_data = templatefile("${path.module}/templates/user-data.sh.tftpl", {
    app_py_b64    = filebase64(var.app_source_path)
    app_version   = var.app_version
    db_secret_arn = var.db_secret_arn
    region        = var.region
    app_port      = var.app_port
  })
}

resource "aws_launch_template" "this" {
  name                   = "${var.name}-web"
  image_id               = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [var.web_sg_id]
  user_data              = base64encode(local.user_data)
  update_default_version = true

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name       = "${var.name}-web"
      Role       = "web"
      AppVersion = var.app_version
    }
  }
}

resource "aws_lb" "this" {
  name               = "${var.name}-alb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "web" {
  # 포트·프로토콜이 바뀌면 교체가 필요한데, 리스너가 쓰는 중이라 먼저 지울 수 없다.
  # name_prefix + create_before_destroy 로 새 타깃 그룹을 먼저 만들고 리스너를 옮긴다.
  name_prefix = "web-"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    matcher             = "200"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = var.alb_listener_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

resource "aws_autoscaling_group" "web" {
  name                = "${var.name}-web"
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity
  vpc_zone_identifier = var.public_subnet_ids
  target_group_arns   = [aws_lb_target_group.web.arn]

  # Floci 인스턴스는 user_data 가 기동 약 1분 뒤에 실행되므로 EC2 상태 검사를 쓴다.
  health_check_type         = "EC2"
  health_check_grace_period = 120

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.name}-web"
    propagate_at_launch = true
  }

  lifecycle {
    # 대수는 scale 워크플로(set-desired-capacity)로도 바뀌므로
    # 다음 apply 가 그 값을 되돌리지 않게 한다. 변수 값은 최초 생성 시에만 적용.
    ignore_changes = [desired_capacity]
  }
}
