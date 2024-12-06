# deploy tasks
operators:
	oc apply -f manifests/operators.yaml

iam-external-secrets:
	scripts/external-secrets.sh

iam-cloudwatch:
	scripts/cloudwatch.sh

virtualization:
	oc apply -f manifests/virtualization.yaml

log-forwarder:
	oc apply -f manifests/log-forwarder.yaml

# NOTE: for demo purposes only
secret:
	aws secretsmanager create-secret \
    	--name MySecret \
    	--secret-string '{"username":"username", "password":"password"}'

openshift-secrets:
	@oc create ns vms --dry-run=client -o yaml | oc apply -f -
	@oc create -n vms secret generic authorized-keys --from-file=ssh-publickey=$$HOME/.ssh/id_rsa.pub --dry-run=client -o yaml | oc apply -f -
	@mkdir cert; cd cert; oc -n openshift-logging extract secret/cloudwatch-vms --confirm; cd ..
	@mkdir ca;   cd ca;   oc extract secret/signing-key --confirm -n openshift-service-ca;            cd ..
	@oc -n vms create configmap syslog-tls --from-file=client-cert.pem=cert/tls.crt --from-file=client-key.pem=cert/tls.key --from-file=ca-cert.pem=ca/tls.crt --dry-run=client -o yaml | oc apply -f -
	@rm -rf cert ca
