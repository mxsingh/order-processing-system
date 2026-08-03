terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  required_version = ">= 1.5.0"

  backend "s3" {
    bucket         = "order-processing-tf-state-994197759584"
    key            = "order-processing/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "order-processing-tf-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "order-processing-system"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}