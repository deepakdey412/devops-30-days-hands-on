terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# Create S3 bucket
resource "aws_s3_bucket" "my-example-bucket" {

  bucket = "deepak-project01-bucket-2026"

  tags = {
    Name        = "My test example bucket"
    Environment = "Dev"
  }
}
