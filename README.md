# Summary

Demonstrate the benefits of leverage OpenShift application platform features and functionality in conjunction with
running virtual machines on OpenShift Virtualization.


## Instructions

1. Deploy a ROSA cluster (this demo assumes OpenShift in a public cloud).  See https://cloud.redhat.com/experts/rosa/ 
for more details.

2. Deploy the infrastructure with the built-in Terraform scripts.

```bash
make infra
```

3. Deploy the operators that provide the needed functionality.

```bash
make operators
```

4. Configure the platform by deploying specific secrets and configs to the cluster.

```bash
make openshift-secrets
```

5. Configure each individual capability.

```bash
make virtualization
make log-forwarder
make external-secrets
```

6. Deploy the VMs

```bash
make gitops
```

7. Follow the [walkthrough](vms/README.md)