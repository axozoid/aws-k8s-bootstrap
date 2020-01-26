## Intro

This sctipt is aimed to do the following:

1. Create AWS infrastructure resources needed for further Kubernetes deployment;
2. Deploy Kubernetes cluster in AWS;
3. Install `Tiller` (Helm's server side component) so we can use easily install K8s packages;
4. Install Nginx Ingress controller;
5. install Prometheus and AlertManger and expose them via an ingress resource. The Web UI is protected by `HTTP auth`.

## What's inside
Please see below the information about the files in this repo:

`bootstrap.sh` - main script containing all the logic and commands;

`vars.sh` - file with variables to customize the installation (WebUI creds are there too);

`main.tf` - Terraform file containing the reference to S3 bucket serving as a backend. [Ref link](https://www.terraform.io/docs/backends/types/s3.html).;

`locals.tf` - that's where we define variables for Terraform which later be used to deploy AWS resources;

`output.tf` - these values should be exported after AWS resources created;

`resources.tf` - in this file we configure which resources to create in AWS;

`tiller-rbac.yaml` - in order to use Helm we need to install Tiller. This file makes it possible;

## Prerequisites 
The following tools have to be installed locally so the sctipt can make use of them:
* jq
* helm (version 2)
* kops
* kubectl
* terraform
* htpasswd

## Getting started

1. Clone this repo
```
git clone git@github.com:axozoid/aws-k8s-bootstrap.git
```
2. Run the main script `bootstrap.sh` without any swithces or with `help` and it will produce self-explanatory output:
```
This script deploys AWS infrastructure and installs Kubernetes into it.
Additionally these components can be installed: Prometheus, Nginx Ingress contoller.

Available options:
* deploy-aws - deploy AWS infrastructure for K8s using 'terraform'
* deploy-k8s - create Kubernetes cluster in AWS using 'kops'
* deploy-infra - create AWS and deploy K8s into it (summary of the steps above)

* install-pr - install Prometheus into K8s cluster using 'helm'
* install-ing - install Nginx ingress controller into K8s cluster using 'helm'
* install-all - install Prometheus and Nginx ingress controller (summary of the steps above)

* deploy-all - deloy infra and install Prometheus and Nginx ingress controller

* delete-pr - delete Prometheus from K8s cluster
* delete-ing - delete Ingress controller from K8s cluster
* cleanup-k8s - destroy K8s cluster and delete related resources in AWS
* cleanup-aws - destroy AWS infrastructure
* cleanup-infra - destroy K8s cluster and delete ALL infra-related AWS resources (summary of the steps above)

* help 	   - show this help
```
3. Assuming you've got valid and configured AWS credentials go and run the script to have everything installed at one go:
```
./bootstrap.sh deploy-all
```
This will deploy needed AWS resources, then deploy Kubernetes and install tiller, ingress controller, prometheus into the newly created Kubernetes cluster.

## Configuration
Please see `vars.sh` for all available options.