VHIVE_VERSION ?= v1.2
KUSTOMIZE ?= kustomize
KUBECONFIG ?= /etc/rancher/k3s/k3s.yaml
KUBECTL ?= kubectl --kubeconfig $(KUBECONFIG)
ISTIOCTL ?= istioctl --kubeconfig $(KUBECONFIG)
REPO_VOL_SIZE ?= 5Gi
VHIVE_CONFIG = https://raw.githubusercontent.com/ease-lab/vhive/${VHIVE_VERSION}/configs

deploy:
	$(KUBECTL) get secret -n metallb-system memberlist || \
		$(KUBECTL) create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
	$(KUBECTL) apply -f $(VHIVE_CONFIG)/knative_yamls/serving-core.yaml
	$(KUBECTL) apply -f $(VHIVE_CONFIG)/knative_yamls/serving-crds.yaml
	curl -sL $(VHIVE_CONFIG)/istio/istio-minimal-operator.yaml | \
		$(ISTIOCTL) install -y -f-
    curl -sL $(VHIVE_CONFIG)/registry/repository-volume.yaml |
		REPO_VOL_SIZE=$(REPO_VOL_SIZE) envsubst | \
        $(KUBECONFIG) apply -f-
	kustomize build | $(KUBECTL) apply  -f-
