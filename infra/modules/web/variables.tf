variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "web_sg_id" {
  type = string
}

variable "alb_listener_port" {
  type    = number
  default = 8080
}

variable "ami_id" {
  description = "Floci 별칭 AMI. ami-amazonlinux2023 → amazonlinux:2023 컨테이너"
  type        = string
  default     = "ami-amazonlinux2023"
}

variable "instance_type" {
  description = "인스턴스 타입 (수직 스케일 실습 대상). Floci 는 카탈로그의 vCPU·메모리로 컨테이너를 제한"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH 키페어 이름. Floci 에서 user_data 는 키 주입 뒤에 실행된다"
  type        = string
  default     = null
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 4
}

variable "desired_capacity" {
  description = "최초 생성 시 웹서버 대수. 이후 변경은 scale 워크플로 사용"
  type        = number
  default     = 2
}

variable "app_source_path" {
  description = "user_data 에 넣을 app.py 경로"
  type        = string
}

variable "app_version" {
  description = "응답에 표시할 앱 버전. 바뀌면 instance refresh 가 일어난다"
  type        = string
}

variable "db_secret_arn" {
  description = "DB 접속 정보가 든 Secrets Manager ARN"
  type        = string
}

variable "app_port" {
  description = "앱 리슨 포트 = 타깃 그룹 포트. Floci EC2 에서는 80 을 IMDS 프록시가 점유한다"
  type        = number
  default     = 8000
}
