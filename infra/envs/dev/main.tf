locals {
  name            = "guestbook-${var.environment}"
  app_source_path = "${path.root}/../../../app/app.py"
  # 앱 코드가 바뀔 때만 버전이 바뀌어 instance refresh 가 일어나도록 내용 해시를 쓴다.
  app_version = var.app_version != "" ? var.app_version : substr(filesha256(local.app_source_path), 0, 8)
}

module "network" {
  source = "../../modules/network"

  name = local.name
  cidr = "10.10.0.0/16"
  azs  = ["${var.region}a", "${var.region}b"]
}

module "db" {
  source = "../../modules/db"

  name              = local.name
  subnet_ids        = module.network.private_subnet_ids
  db_sg_id          = module.network.db_sg_id
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage
}

# SSH 키는 선택 사항(M6 Ansible 실습용). scripts/new-ssh-key.ps1 로 만들면 자동으로 등록된다.
locals {
  ssh_pub_key_path = "${path.root}/../../../provision/keys/lab_ed25519.pub"
  has_ssh_key      = fileexists(local.ssh_pub_key_path)
}

resource "aws_key_pair" "web" {
  count      = local.has_ssh_key ? 1 : 0
  key_name   = "${local.name}-web"
  public_key = local.has_ssh_key ? file(local.ssh_pub_key_path) : ""
}

module "web" {
  source = "../../modules/web"

  name              = local.name
  region            = var.region
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  alb_sg_id         = module.network.alb_sg_id
  web_sg_id         = module.network.web_sg_id
  key_name          = local.has_ssh_key ? aws_key_pair.web[0].key_name : null

  instance_type    = var.web_instance_type
  min_size         = var.web_min_size
  max_size         = var.web_max_size
  desired_capacity = var.web_desired_capacity

  app_source_path = local.app_source_path
  app_version     = local.app_version
  db_secret_arn   = module.db.secret_arn
}
