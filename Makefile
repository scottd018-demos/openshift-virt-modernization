# deploy tasks

# step 1: create aws infrastructure
.PHONY: infra
infra:
	@cd infra && \
		terraform init && \
		export TF_VAR_oidc_provider=$$(oc get authentication.config.openshift.io cluster -o json | jq -r .spec.serviceAccountIssuer | sed -e "s/^https:\/\///") && \
		terraform apply

infra-destroy:
	@cd infra && \
		terraform init && \
		export TF_VAR_oidc_provider=$$(oc get authentication.config.openshift.io cluster -o json | jq -r .spec.serviceAccountIssuer | sed -e "s/^https:\/\///") && \
		terraform apply -destroy

# step 2: deploy operators
operators:
	oc apply -f manifests/operators.yaml

# step 3: create configurations
openshift-secrets:
	@oc create ns vms --dry-run=client -o yaml | oc apply -f -
	@oc create -n vms secret generic authorized-keys --from-file=ssh-publickey=$$HOME/.ssh/id_rsa.pub --dry-run=client -o yaml | oc apply -f -
	@mkdir cert; cd cert; oc -n openshift-logging extract secret/cloudwatch-vms --confirm; cd ..
	@mkdir ca;   cd ca;   oc extract secret/signing-key --confirm -n openshift-service-ca;            cd ..
	@oc -n vms create configmap syslog-tls --from-file=client-cert.pem=cert/tls.crt --from-file=client-key.pem=cert/tls.key --from-file=ca-cert.pem=ca/tls.crt --dry-run=client -o yaml | oc apply -f -
	@rm -rf cert ca

# step 4: configure operators
virtualization:
	oc apply -f manifests/virtualization.yaml

log-forwarder:
	oc apply -f manifests/log-forwarder.yaml

external-secrets:
	oc apply -f manifests/external-secrets.yaml

# step 5: deploy vms from gitops
gitops:
	oc apply -f manifests/gitops.yaml
