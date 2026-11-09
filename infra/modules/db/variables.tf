variable "name" {
  description = "리소스 이름 접두사"
  type        = string
}

variable "subnet_ids" {
  description = "DB 서브넷 그룹에 넣을 프라이빗 서브넷"
  type        = list(string)
}

variable "db_sg_id" {
  description = "DB 보안 그룹 ID"
  type        = string
}

variable "engine_version" {
  type    = string
  default = "16"
}

variable "instance_class" {
  description = "DB 인스턴스 클래스 (수직 스케일 실습 대상)"
  type        = string
  default     = "db.t3.micro"
}

variable "allocated_storage" {
  description = "스토리지 GiB"
  type        = number
  default     = 20
}

variable "db_name" {
  type    = string
  default = "guestbook"
}

variable "username" {
  type    = string
  default = "app"
}
