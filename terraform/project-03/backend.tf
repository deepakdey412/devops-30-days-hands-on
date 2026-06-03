terraform {
  backend "s3" {
    bucket = "mera-test-bucket-01"
    key    = "project-02/terraform.tfstate"
    region = "ap-south-1"
  }
}
