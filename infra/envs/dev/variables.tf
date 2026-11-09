variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "floci_endpoint" {
  description = "Floci 엔드포인트. 실수로 실제 AWS 를 가리키지 않도록 로컬 주소만 허용"
  type        = string
  default     = "http://localhost:4566"

  validation {
    condition     = can(regex("^http://(localhost|127\\.0\\.0\\.1|host\\.docker\\.internal|floci)(:[0-9]+)?$", var.floci_endpoint))
    error_message = "floci_endpoint 는 로컬 Floci 주소여야 합니다 (예: http://localhost:4566)."
  }
}

# ---------- 웹 계층 ----------

variable "web_instance_type" {
  description = "웹서버 인스턴스 타입 (수직 스케일)"
  type        = string
  default     = "t3.micro"
}

variable "web_min_size" {
  type    = number
  default = 1
}

variable "web_max_size" {
  type    = number
  default = 4
}

variable "web_desired_capacity" {
  description = "최초 웹서버 대수 (수평 스케일은 scale 워크플로로)"
  type        = number
  default     = 2
}

variable "app_version" {
  description = "앱 버전 표시값. 비우면 app.py 내용의 해시 앞 8자리"
  type        = string
  default     = ""
}

# ---------- DB 계층 ----------

variable "db_instance_class" {
  description = "DB 인스턴스 클래스 (수직 스케일)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type    = number
  default = 20
}
