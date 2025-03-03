terraform {
  backend "s3" {
    bucket = "ky-s3-terraform"
    key    = "ky-tf-function-s3bucket.tfstate"
    region = "us-east-1"
  }
}
