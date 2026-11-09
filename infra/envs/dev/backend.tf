# Terraform state 를 Floci 의 S3 에 저장한다.
# 수강생 PC 와 self-hosted runner 가 같은 state 를 공유하기 위해서다.
# 최초 1회: scripts/bootstrap-state.ps1 로 tfstate 버킷을 만든 뒤 terraform init.

terraform {
  backend "s3" {
    bucket       = "tfstate"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true # S3 잠금 파일(.tflock)로 동시 apply 방지

    access_key                  = "test"
    secret_key                  = "test"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    use_path_style              = true

    endpoints = {
      s3 = "http://localhost:4566"
    }
  }
}
