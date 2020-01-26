# our variables
locals {
  environment             = "stage"
  kubernetes_dns_zone     = "k8s.local"
  kubernetes_cluster_name = "${local.environment}.${local.kubernetes_dns_zone}"
  vpc_name                = "vpc_${local.environment}"
  kops_state_bucket_name  = "${local.environment}-kops-state-bucket"
  cidr                    = "10.10.0.0/20"
  // from these IPs our cluster will be accessible (access from everywhere by default)
  ingress_ips     = ["0.0.0.0/0"]
  subnets_private = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  subnets_public  = ["10.10.10.0/24", "10.10.20.0/24", "10.10.30.0/24"]
  azs             = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]

  tags_common = {
    environment = "${local.environment}"
    terraform   = true
  }
}