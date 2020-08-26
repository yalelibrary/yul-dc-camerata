# provider.tf

# Specify the provider and access details
provider "aws" {
  profile = "dc-hosting-mml"
  region  = var.aws_region
}

