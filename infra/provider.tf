terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
        archive = {
            source = "hashicorp/archive"
            version = "~> 2.4"
        }
    }

    required_version = ">= 1.5.0"
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