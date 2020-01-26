#!/usr/bin/env bash

AWS_PROFILE=default

PROMETHEUS_YAML=prometheus-alertmanager-ingress.yaml
TF_OUTPUT=tf_output.json
TILLER_RBAC=tiller-rbac.yaml
TILLER_ACCOUNT=tiller

KOPS_MASTER_TYPE=t2.micro
KOPS_MASTER_COUNT=3
KOPS_NODE_COUNT=1
KOPS_NODE_TYPE=t2.micro
KOPS_TOPOLOGY=public
KOPS_NETWORK=calico

# these vars will be calculated durint the script run
KOPS_VPC_ID=""
KOPS_DNS_ZONE=""
KOPS_CLUSTER_NAME=""
KOPS_KOPS_STATE_BUCKET=""
KOPS_AWS_ZONES=""

K8S_NS_PROMETHEUS=monitoring
K8S_NS_NGINX=nginx-ingress

HELM_RELEASE_PROMETHEUS=prometheus
HELM_RELEASE_PROMETHEUS_VERSION=9.1.1

HELM_RELEASE_NGINX=nginx-ingress


PROMETHEUS_USER=admin
PROMETHEUS_PASSWORD=Pr0m3th3uSPwD

