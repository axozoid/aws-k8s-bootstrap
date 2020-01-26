
#!/usr/bin/env bash
vars="vars.sh"

if [ -f "${vars}" ]; then
    source "${vars}"
else
    echo "ERROR: File ${vars} not found."
    exit 1
fi

# set -eo pipefail

function check_app {
	for i in "$@"
	do
		which -s ${i} || { echo "[ERROR] binary not found: ${i}"; exit 1; }
	done
}

function deploy_aws {
    echo "[INFO] Deploying AWS infrastracture.."
	terraform apply -auto-approve
	terraform output -json > "${TF_OUTPUT}"

}

function show_help {
	echo ""
	echo "This script deploys AWS infrastructure and installs Kubernetes into it."
	echo "Additionally these components can be installed: Prometheus, Nginx Ingress contoller." 
	echo ""
	echo "Available options:"
	echo "* deploy-aws - deploy AWS infrastructure for K8s using 'terraform'"
	echo "* deploy-k8s - create Kubernetes cluster in AWS using 'kops'"
	echo "* deploy-infra - create AWS and deploy K8s into it (summary of the steps above)"
	echo ""
	echo "* install-pr - install Prometheus into K8s cluster using 'helm'"
	echo "* install-ing - install Nginx ingress controller into K8s cluster using 'helm'"
	echo "* install-all - install Prometheus and Nginx ingress controller (summary of the steps above)"
	echo ""
	echo "* deploy-all - deloy infra and install Prometheus and Nginx ingress controller"
	echo ""
	echo "* cleanup-k8s - destroy K8s cluster and delete related resources in AWS"
	echo "* cleanup-aws - destroy AWS infrastructure"
	echo "* cleanup-infra - destroy K8s cluster and delete ALL infra-related resources in AWS (summary of the steps above)"
	echo "" 
	echo "* help 	   - show this help"
	echo "" 
}

function get_outputs {
	terraform output -json > "${TF_OUTPUT}"
	grep 'vpc_id' "${TF_OUTPUT}" > /dev/null
	if [ $? -eq 0 ]; then
		echo "[INFO] Getting AWS resource details.. "
		KOPS_VPC_ID=$(jq -r '.vpc_id.value' ${TF_OUTPUT})
		KOPS_DNS_ZONE=$(jq -r '.k8s_dns_zone.value' ${TF_OUTPUT})
		KOPS_CLUSTER_NAME=$(jq -r '.kubernetes_cluster_name.value' ${TF_OUTPUT})
		KOPS_KOPS_STATE_BUCKET=$(jq -r '.kops_state_bucket_name.value' ${TF_OUTPUT})
		KOPS_AWS_ZONES=$(jq -r '.availability_zones.value[0] | join(",")' ${TF_OUTPUT})
		echo "[INFO] Loaded data: ${KOPS_VPC_ID}, ${KOPS_DNS_ZONE}, ${KOPS_CLUSTER_NAME}, ${KOPS_KOPS_STATE_BUCKET}, ${KOPS_AWS_ZONES}"
	else
		# exit if AWS side wasn't deployed
		[ "${1}" ] && { echo "[ERROR] AWS infrastructure isn't deployed."; exit 0; }
	fi

}

function deploy_k8s {
	get_outputs 1
	echo "[INFO] Creating K8s cluster.."
	kops create cluster \
		--state s3://${KOPS_KOPS_STATE_BUCKET} \
		--master-zones ${KOPS_AWS_ZONES} \
		--zones ${KOPS_AWS_ZONES} \
		--topology ${KOPS_TOPOLOGY} \
		--dns-zone ${KOPS_DNS_ZONE} \
		--networking ${KOPS_NETWORK} \
		--vpc ${KOPS_VPC_ID} \
		--master-count ${KOPS_MASTER_COUNT} \
		--master-size=${KOPS_MASTER_TYPE} \
		--node-size=${KOPS_NODE_TYPE} \
		--node-count ${KOPS_NODE_COUNT} \
		${KOPS_CLUSTER_NAME} \
		--yes
	
	until kubectl get nodes >/dev/null 2>&1
	do
		echo "[INFO] Waiting for cluster to be ready.."
		sleep 5
	done
	echo "[INFO] Cluster is ready."
	install_tiller
}

# TODO: check if the tiller exists
function install_tiller {
	if [ -f "${TILLER_RBAC}" ]; then
		echo "[INFO] Installing tiller.."
		kubectl apply -f "${TILLER_RBAC}"
		helm init --service-account "${TILLER_ACCOUNT}"
	else
		echo "ERROR: File ${TILLER_RBAC} not found."
		exit 1
	fi

	until kubectl -n kube-system get pods | grep tiller | grep Running | grep '1/1' 
	do
		echo "[INFO] Waiting for tiller to be ready.."
		sleep 2
	done
	echo "[INFO] Tiller is ready."
}

function generate_prometheus_secret {
	echo "[INFO] Generating Prometheus configs.."
	kubectl get ns "${K8S_NS_PROMETHEUS}" || kubectl create namespace "${K8S_NS_PROMETHEUS}"
	htpasswd -c -b auth "${PROMETHEUS_USER}" "${PROMETHEUS_PASSWORD}"
	kubectl --namespace "${K8S_NS_PROMETHEUS}" get secret basic-auth || kubectl --namespace "${K8S_NS_PROMETHEUS}" create secret generic basic-auth --from-file=auth
	rm -rf auth
}

function generate_yaml {
	generate_prometheus_secret
	rm -rf "${PROMETHEUS_YAML}" && touch "${PROMETHEUS_YAML}"
	for i in "$@"
	do
		cat >> "${PROMETHEUS_YAML}" << EOL
${i}:
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: nginx
      nginx.ingress.kubernetes.io/auth-type: basic
      nginx.ingress.kubernetes.io/auth-secret: basic-auth
      nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
    hosts:
    - ${i}.${KOPS_CLUSTER_NAME}

EOL
	done
	rm -rf "${PROMETHEUS_YAML}"
}

function hosts_tip {
	LB_DNS_NAME=$(kubectl -n "${K8S_NS_NGINX}" get svc | grep LoadBalancer | awk '{ print $4 }')
	until [ "${IP2HOST}" ]
	do
		IP2HOST=$(dig +short ${LB_DNS_NAME} | head -n1)
		echo "[INFO] Waiting for Ingress' ELB to be provisioned.."
		sleep 2
	done
	echo "**************************************************************"
	echo "In order to test Prometheus, point the following hostnames:"
	kubectl -n monitoring get ing --no-headers=true | awk '{print $2}'
	echo "To IP address ${IP2HOST} using '/etc/hosts' file."
	echo ""
	echo "Username: ${PROMETHEUS_USER}"
	echo "Password: ${PROMETHEUS_PASSWORD}"
	echo "**************************************************************"
}

function install_prometheus {
	# get_outputs
	generate_yaml server alertmanager
	# helm ls | grep "${HELM_RELEASE_PROMETHEUS}" | grep 'DEPLOYED'
	echo "[INFO] Installing Prometheus.."
	helm install --name "${HELM_RELEASE_PROMETHEUS}" --namespace "${K8S_NS_PROMETHEUS}" --version "${HELM_RELEASE_PROMETHEUS_VERSION}" -f "${PROMETHEUS_YAML}" stable/prometheus
	hosts_tip
}


function install_ingress {
	# TODO: check if the tiller exists
	echo "[INFO] Installing Nginx Ingress controller.."
	helm install stable/nginx-ingress --namespace "${K8S_NS_NGINX}" --name "${HELM_RELEASE_NGINX}" --set rbac.create=true --wait

}

function install_vault {
	# TODO: check if the tiller exists
	echo ""
}

function cleanup_aws {
	echo "[INFO] Deleting AWS infrastracture.."
	terraform destroy -auto-approve
}

function cleanup_k8s {
	echo "[INFO] Deleting K8s cluster.."
	kops delete cluster \
		--state s3://${KOPS_KOPS_STATE_BUCKET} \
		${KOPS_CLUSTER_NAME} \
		--yes
}

function delete_prometheus {
	# TODO: check if exists
	helm delete "${HELM_RELEASE_PROMETHEUS}" --purge
}

function delete_ingress {
	# TODO: check if exists
	echo "[INFO] Deleting Ingress Controller"
	helm delete "${HELM_RELEASE_NGINX}" --purge
}

# set -x 
check_app jq helm kops kubectl terraform htpasswd
get_outputs

case ${1} in
deploy-aws)
    deploy_aws
    ;;
deploy-k8s)
	deploy_k8s
    ;;
install-tiller)
	install_tiller
    ;;
install-ing)
	install_ingress
    ;;
install-pr)
	install_prometheus
	;;
install-all)
	install_ingress
	install_prometheus
    ;;
delete-pr)
	delete_prometheus
    ;;
install-vl)
	hosts_tip
    ;;
deploy-infra)
	deploy_aws
	deploy_k8s
    ;;
deploy-all)
	deploy_aws
	deploy_k8s
	install_ingress
	install_prometheus
    ;;
cleanup-aws)
	cleanup_aws
    ;;
cleanup-k8s)
	cleanup_k8s
    ;;
cleanup-infra)
	cleanup_k8s
	cleanup_aws
    ;;
update-auth)
	generate_prometheus_secret
    ;;
*)
    show_help
    exit 0
    ;;
esac

