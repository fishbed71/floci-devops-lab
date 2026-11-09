output "app_url" {
  description = "브라우저 접속 주소 (ALB 리스너를 compose.yaml 이 호스트 8080 으로 노출)"
  value       = "http://localhost:8080"
}

output "app_version" {
  value = local.app_version
}

output "asg_name" {
  value = module.web.asg_name
}

output "alb_dns_name" {
  value = module.web.alb_dns_name
}

output "db_host_port" {
  description = "호스트(PC)에서 psql 로 접속할 포트: localhost:<이 값>"
  value       = module.db.port
}

output "db_secret_arn" {
  value = module.db.secret_arn
}
