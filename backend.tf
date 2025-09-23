terraform {
  required_version = ">= 1.10.0"

  # Empty on purpose — the workflow writes backend.hcl and passes it at init time
  backend "s3" {}

  required_providers {
    aws = { source = "hashicorp/aws", version = ">= 5.0" }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type    = string
  default = "us-east-1"  # change if needed
}

