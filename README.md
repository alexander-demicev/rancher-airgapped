# Rancher Air-Gapped Installation Guide
# Dev purpose only

This guide provides step-by-step instructions for installing Rancher in an air-gapped environment using local resources.

## Prerequisites

- [Kind](https://kind.sigs.k8s.io/) installed
- Access to required Rancher and other necessary Docker images
- Helm v3 installed
- Necessary YAML configuration files available locally

## Steps

### 1. Create a Kind Cluster

```bash
kind create cluster --config kind-cluster-with-extramounts.yaml
```

### 2. Pull and Load Required Docker Images

```bash
# Ensure login to GHCR before running this part
while IFS= read -r line; do
    docker pull "$line"
    kind load docker-image "$line" --name=capi-test
done < "rancher-images.txt"
```

### 3. Install Cert-Manager

```bash
helm install cert-manager ./charts/cert-manager-v1.12.3.tgz \
    --namespace cert-manager \
    --create-namespace \
    --version v1.12.3 \
    --set installCRDs=true \
    --wait
```

### 4. Apply Nginx Configuration

```bash
kubectl apply -f nginx.yaml
```

### 5. Install Rancher

```bash
export RANCHER_HOSTNAME="<your_rancher_hostname>"

helm install rancher ./charts/rancher-2.7.9.tgz \
    --namespace cattle-system \
    --create-namespace \
    --set replicas=1 \
    --set hostname="$RANCHER_HOSTNAME" \
    --set global.cattle.psp.enabled=false \
    --set 'extraEnv[0].name=CATTLE_FEATURES' \
    --set 'extraEnv[0].value=embedded-cluster-api=false' \
    --set useBundledSystemChart=true \
    --version v2.7.9
```

### 6. Install Rancher Turtles

```bash
helm install rancher-turtles ./charts/rancher-turtles-0.0.0-3461d67685276596682740624123ff5383648cf5.tgz \
    --version 0.0.0-3461d67685276596682740624123ff5383648cf5 \
    -n rancher-turtles-system --create-namespace \
    --set cluster-api-operator.cert-manager.enabled=false \
    --set cluster-api-operator.cluster-api.enabled=false \
    --set=rancherTurtles.features.embedded-capi.disabled=false \
    --dependency-update --wait --timeout 180s
```

### 7. Apply Manifests and Configuration

```bash
kubectl create -f manifests/
kubectl create -f capi-variables.yaml # Add vsphere username and password here before proceeding, and other required credential variables
kubectl create -f capi-providers.yaml
```
