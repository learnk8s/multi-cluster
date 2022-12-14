# Multi-cluster, multi-region, multi-cloud Kubernetes

This project helps you bootstrap and orchestrate several Kubernetes clusters across different regions and clouds from a single control plane.

![Scaling Kubernetes clusters across regions and clouds](assets/preview.gif)

The setup helps study:

- High availability installation of Kubernetes.
- Multi-region deployments.
- Multi-cloud deployments.
- Upgrading clusters and apps.

## Getting started

You need to create a Linode token to access the API:

```bash
linode-cli profile token-create
export LINODE_TOKEN=<insert the token here>
```

```bash
# Create the clusters
terraform -chdir=01-clusters init
terraform -chdir=01-clusters apply -auto-approve

# Install Karmada in the cluster manager
terraform -chdir=02-karmada init
terraform -chdir=02-karmada apply -auto-approve

# Configure the Karmada workers and install Istio
terraform -chdir=03-workers init
terraform -chdir=03-workers apply -auto-approve

# Discover other Istio installations
terraform -chdir=04-discovery init
terraform -chdir=04-discovery apply -auto-approve

# Install Kiali
terraform -chdir=05-dashboards init
terraform -chdir=05-dashboards apply -auto-approve

# Clean up
terraform -chdir=05-dashboards destroy -auto-approve
terraform -chdir=04-discovery destroy -auto-approve
terraform -chdir=03-workers destroy -auto-approve
terraform -chdir=02-karmada destroy -auto-approve
terraform -chdir=01-clusters destroy -auto-approve
```

## Accessing the Kiali dashboard

```bash
kubectl --kubeconfig=kubeconfig-ap port-forward svc/kiali 8081:20001 -n istio-system
```

## Testing the code

```bash
./test.sh
```

The script will print the command you can use to launch the world map dashboard.

## Creating new certs

```bash
$ git clone https://github.com/istio/istio
```

Create a `certs` folder and change to that directory:

```bash
$ mkdir certs
$ cd certs
```

Create the root certificate with:

```bash
$ make -f ../istio/tools/certs/Makefile.selfsigned.mk root-ca
```

The command generated the following files:

- `root-cert.pem`: the generated root certificate.
- `root-key.pem`: the generated root key.
- `root-ca.conf`: the configuration for OpenSSL to generate the root certificate.
- `root-cert.csr`: the generated CSR for the root certificate.

For each cluster, generate an intermediate certificate and key for the Istio Certificate Authority:

```bash
$ make -f ../istio/tools/certs/Makefile.selfsigned.mk cluster1-cacerts
$ make -f ../istio/tools/certs/Makefile.selfsigned.mk cluster2-cacerts
$ make -f ../istio/tools/certs/Makefile.selfsigned.mk cluster3-cacerts
```

## Notes

- Sometimes, the EastWest gateway cannot be created because of a validation admission webhook. Since this is sporadic, I think it's related to a race condition. [More on this here.](https://github.com/istio/istio/issues/39205)
- This Terraform files use the `null_resource` and `kubectl`. You should have `kubectl` installed locally.
