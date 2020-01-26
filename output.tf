output "region" {
  value = "${data.aws_region.current.name}"
}

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "vpc_name" {
  value = "${local.vpc_name}"
}

output "vpc_cidr_block" {
  value = "${module.vpc.vpc_cidr_block}"
}

output "availability_zones" {
  value = ["${local.azs}"]
}

output "k8s_dns_zone" {
  value = "${local.kubernetes_dns_zone}"
}

output "kops_state_bucket_name" {
  value = "${local.kops_state_bucket_name}"
}

output "kubernetes_cluster_name" {
  value = "${local.kubernetes_cluster_name}"
}