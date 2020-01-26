
provider "aws" {
  region  = "ap-southeast-2"
  version = "~> 2.46.0"
}


# S3 State store for Terraform
terraform {
  backend "s3" {
    region = "ap-southeast-2"
    bucket = "k8s-clusters-backend"
    key    = "tf"

  }
}
