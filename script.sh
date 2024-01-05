./rancher-save-images.sh --image-list ./rancher-images.txt

cat > kind-cluster-with-extramounts.yaml <<EOF
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: capi-test
nodes:
- role: control-plane
  image: kindest/node:v1.26.6
  extraMounts:
    - hostPath: /var/run/docker.sock
      containerPath: /var/run/docker.sock
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF

kind create cluster --config kind-cluster-with-extramounts.yaml

helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --version v1.12.3 \
    --set installCRDs=true \
    --wait

kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
    
helm install rancher rancher-stable/rancher \
--namespace cattle-system \
--create-namespace \
--set replicas=1 \
--set hostname="$RANCHER_HOSTNAME" \
--set global.cattle.psp.enabled=false \
--set 'extraEnv[0].name=CATTLE_FEATURES' \
--set 'extraEnv[0].value=embedded-cluster-api=false' \
--version v2.7.9
  
helm install rancher-turtles oci://ghcr.io/rancher-sandbox/rancher-turtles-chart/rancher-turtles \
  --version 0.0.0-3461d67685276596682740624123ff5383648cf5 -n rancher-turtles-system --create-namespace \
  --set cluster-api-operator.cert-manager.enabled=false \
  --set cluster-api-operator.cluster-api.enabled=false \
  --set=rancherTurtles.features.embedded-capi.disabled=false \
  --dependency-update --wait --timeout 180s

kubectl create -f manifests/

kubectl create -f capi-providers.yaml