terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.40.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.region
}

# ✅ Key pair
resource "aws_key_pair" "demo_key" {
  key_name   = "nca-demo-key"
  public_key = file(var.ssh_key)
}

# Note: No individual EC2 outputs anymore, ALB DNS is used instead
