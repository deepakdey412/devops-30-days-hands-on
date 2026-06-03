resource "aws_s3_bucket" "my_example_bucket" {

  bucket = var.bucket_name

  tags = {
    Name        = "My Test Example Bucket"
    Environment = var.environment
  }
}
