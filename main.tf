terraform {
  required_providers {
    localos = {
      source  = "fireflycons/localos"
      version = "0.2.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.64.0"
    }
  }
}
provider "aws" {
  region = var.aws_region
}
provider "localos" {}

