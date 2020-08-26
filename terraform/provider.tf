# provider.tf

# Specify the provider and access details
provider "aws" {
  profile = "dce-hosting-mml"
  region  = var.aws_region
}

