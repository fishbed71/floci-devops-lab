# RDS PostgreSQL 1대 + 접속 정보를 담은 Secrets Manager 비밀
# Floci 에서는 postgres:16-alpine 컨테이너가 실제로 뜬다.

resource "random_password" "master" {
  length  = 24
  special = false # URL·셸 이스케이프 문제를 피하려고 특수문자 제외
}

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db"
  subnet_ids = var.subnet_ids
  tags       = { Name = "${var.name}-db" }
}

resource "aws_db_instance" "this" {
  identifier             = "${var.name}-db"
  engine                 = "postgres"
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  db_name                = var.db_name
  username               = var.username
  password               = random_password.master.result
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [var.db_sg_id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  apply_immediately      = true
  tags                   = { Name = "${var.name}-db" }
}

resource "aws_secretsmanager_secret" "db" {
  name                    = "${var.name}/db"
  description             = "Guestbook DB connection info"
  recovery_window_in_days = 0 # 실습용: destroy 후 같은 이름으로 바로 재생성 가능
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    host     = aws_db_instance.this.address
    port     = aws_db_instance.this.port
    dbname   = var.db_name
    username = var.username
    password = random_password.master.result
  })
}
