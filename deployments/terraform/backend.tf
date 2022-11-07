

terraform {
  backend "s3" {
    endpoint                    = "ams3.digitaloceanspaces.com"
    key                         = "mpyc-demo/terraform.tfstate"
    bucket                      = "mpyc-tf-state"
    region                      = "ams3"
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_metadata_api_check     = true
  }
}
