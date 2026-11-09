output "address" {
  description = "DB 엔드포인트 주소 (Floci: 웹 인스턴스 컨테이너에서 접근 가능한 주소)"
  value       = aws_db_instance.this.address
}

output "port" {
  description = "DB 포트 (Floci: 호스트에서는 localhost:<이 포트>)"
  value       = aws_db_instance.this.port
}

output "secret_arn" {
  value = aws_secretsmanager_secret.db.arn
}

output "identifier" {
  value = aws_db_instance.this.identifier
}
