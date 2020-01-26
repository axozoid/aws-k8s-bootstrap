data "aws_region" "current" {}

resource "aws_s3_bucket" "kops_state_bucket" {
  bucket        = "${local.kops_state_bucket_name}"
  acl           = "private"
  force_destroy = true
  tags          = "${merge(local.tags_common)}"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${local.vpc_name}"
  cidr = "${local.cidr}"
  azs  = "${local.azs}"

  enable_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true


  tags = {
    // allow kops to use the VPC resources
    "kubernetes.io/cluster/${local.kubernetes_cluster_name}" = "shared"
    "terraform"                                              = true
    "environment"                                            = "${local.environment}"
  }

}

resource "aws_internet_gateway" "gw" {
  vpc_id     = "${module.vpc.vpc_id}"
  depends_on = [module.vpc]
  tags = {
    Name = "${local.kubernetes_dns_zone}"
  }
}

resource "aws_route53_zone" "private" {
  name       = "${local.kubernetes_dns_zone}"
  depends_on = [module.vpc]
  vpc {
    vpc_id = "${module.vpc.vpc_id}"
  }
}
