variable "name" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.10.0.0/16"
}

variable "azs" {
  description = "사용할 가용 영역 목록"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "alb_listener_port" {
  description = "ALB 리스너 포트 (compose.yaml 에서 호스트로 노출한 포트와 같아야 함)"
  type        = number
  default     = 8080
}

variable "expose_web_to_host" {
  description = "Floci 전용: 웹 인스턴스 앱 포트를 localhost:300xx 로 노출"
  type        = bool
  default     = true
}

variable "app_port" {
  description = "웹 인스턴스의 앱 포트. Floci EC2 컨테이너는 IMDS 프록시가 80 을 점유하므로 8000 사용"
  type        = number
  default     = 8000
}
