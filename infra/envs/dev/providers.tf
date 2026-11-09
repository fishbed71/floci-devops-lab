# 모든 AWS 호출을 Floci 로 보낸다.
# 이 과정에서 쓰는 서비스는 endpoints 에 빠짐없이 적어야 한다.
# 빠진 서비스는 실제 AWS 로 요청이 나가 인증 오류가 난다.

provider "aws" {
  region     = var.region
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  s3_use_path_style           = true
  # skip_requesting_account_id 는 쓰지 않는다. 계정 ID(000000000000)를 Floci STS 에서 받아야
  # 보안 그룹 참조 규칙이 "다른 계정 SG"로 오인되어 매 plan 마다 변경으로 뜨는 문제를 피한다.

  endpoints {
    autoscaling    = var.floci_endpoint
    dynamodb       = var.floci_endpoint
    ec2            = var.floci_endpoint
    elbv2          = var.floci_endpoint
    iam            = var.floci_endpoint
    rds            = var.floci_endpoint
    s3             = var.floci_endpoint
    secretsmanager = var.floci_endpoint
    ssm            = var.floci_endpoint
    sts            = var.floci_endpoint
  }

  default_tags {
    tags = {
      Project     = "floci-devops-lab"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
