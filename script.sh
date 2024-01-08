kind create cluster --config kind-cluster-with-extramounts.yaml

# Login to GHCR before running this part
while IFS= read -r line; do
    docker pull "$line"
    kind load docker-image "$line" --name=capi-test
done < "rancher-images.txt"

helm install cert-manager ./charts/cert-manager-v1.12.3.tgz \
    --namespace cert-manager \
    --create-namespace \
    --version v1.12.3 \
    --set installCRDs=true \
    --wait

kubectl apply -f nginx.yaml
    
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
  
helm install rancher-turtles ./charts/rancher-turtles-0.0.0-3461d67685276596682740624123ff5383648cf5.tgz \
  --version 0.0.0-3461d67685276596682740624123ff5383648cf5 -n rancher-turtles-system --create-namespace \
  --set cluster-api-operator.cert-manager.enabled=false \
  --set cluster-api-operator.cluster-api.enabled=false \
  --set=rancherTurtles.features.embedded-capi.disabled=false \
  --dependency-update --wait --timeout 180s

kubectl create -f manifests/

kubectl create -f capi-variables.yaml # Add vsphere username and password here before proceeding, and other required credential variables
kubectl create -f capi-providers.yaml