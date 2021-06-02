VHIVE_VERSION ?= v1.2
KNATIVE_VERSION ?= v0.21.0
METALLB_VERSION ?= v0.9.4
KUSTOMIZE ?= kustomize build
KUBECONFIG ?= /etc/rancher/k3s/k3s.yaml
KUBECTL ?= kubectl --kubeconfig $(KUBECONFIG)
ISTIOCTL ?= istioctl --kubeconfig $(KUBECONFIG)
ENVSUBST ?= envsubst
REPO_VOL_SIZE ?= 5Gi
VHIVE_CONFIG ?= https://raw.githubusercontent.com/ease-lab/vhive/${VHIVE_VERSION}/configs
KNATIVE_CONFIG ?= https://github.com/knative/eventing/releases/download/$(KNATIVE_VERSION)
METALLB_CONFIG ?= https://raw.githubusercontent.com/metallb/metallb/$(METALLB_VERSION)/manifests
MINIO_CONFIG ?= $(VHIVE_CONFIG)/storage/minio
MINIO_PATH ?= /var/lib/k3s-minio

deploy:
	$(KUBECTL) apply -f $(METALLB_CONFIG)/namespace.yaml
	$(KUBECTL) apply -f $(METALLB_CONFIG)/metallb.yaml
	$(KUBECTL) apply -f ${VHIVE_CONFIG}/metallb/metallb-configmap.yaml
	$(KUBECTL) get secret -n metallb-system memberlist || \
		$(KUBECTL) create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
	$(KUBECTL) apply -f $(VHIVE_CONFIG)/calico/canal.yaml
	curl -sL $(VHIVE_CONFIG)/istio/istio-minimal-operator.yaml | \
		$(ISTIOCTL) install -y -f-
	$(KUBECTL) apply -f $(VHIVE_CONFIG)/knative_yamls/serving-core.yaml
	$(KUBECTL) apply -f $(VHIVE_CONFIG)/knative_yamls/serving-crds.yaml
	$(KUBECTL) apply -f $(KNATIVE_CONFIG)/eventing-core.yaml
	$(KUBECTL) apply -f https://github.com/knative/net-istio/releases/download/$(KNATIVE_VERSION)/release.yaml
	$(KUBECTL) apply -f $(KNATIVE_CONFIG)/in-memory-channel.yaml
	$(KUBECTL) apply -f $(KNATIVE_CONFIG)/mt-channel-broker.yaml
	$(MAKE) minio
	$(KUBECTL) create namespace registry || true
	REPO_VOL_SIZE=$(REPO_VOL_SIZE) $(ENVSUBST) < repository-volume.yaml | \
		$(KUBECTL) apply -f-
	$(KUBECTL) apply -f $(VHIVE_CONFIG)/registry/repository-update-hosts.yaml
	$(KUBECTL) apply -f $(VHIVE_CONFIG)/knative_yamls/serving-default-domain.yaml
	$(KUBECTL) --namespace istio-system get service istio-ingressgateway

minio:
	mkdir -p $(MINIO_PATH)
	# create a persistent volume (PV) and the corresponding PV claim
    # specify the node name that would host the MinIO objects
	# (use `hostname` command for the local node)
	curl -sL $(MINIO_CONFIG)/pv.yaml | \
		MINIO_NODE_NAME=$(shell hostname) MINIO_PATH=$(MINIO_PATH) $(ENVSUBST) | \
        $(KUBECTL) apply -f-
	$(KUBECTL) apply -f $(MINIO_CONFIG)/pv-claim.yaml
	# create a storage app and the corresponding service
	$(KUBECTL) apply -f $(MINIO_CONFIG)/deployment.yaml
	curl -sL $(MINIO_CONFIG)/service.yaml | \
		sed -e 's!clusterIP: .*!clusterIP: 10.43.254.254!' | \
        $(KUBECTL) apply -f-
