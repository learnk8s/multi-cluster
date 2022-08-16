#! /bin/bash

cat <<EOF | kubectl --kubeconfig=kubeconfig-sg apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: region
data:
  name: 👋 🇸🇬 Hello from Singapore
EOF

cat <<EOF | kubectl --kubeconfig=kubeconfig-eu apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: region
data:
  name: 👋 🇬🇧 Hello from London, UK
EOF

cat <<EOF | kubectl --kubeconfig=kubeconfig-us apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: region
data:
  name: 👋 🇺🇸 Hello from Fremont, CA
EOF

cat <<EOF | kubectl --kubeconfig=karmada-config apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello
spec:
  replicas: 3
  selector:
    matchLabels:
      app: hello
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - image: stefanprodan/podinfo
        name: hello
        env:
          - name: REGION
            valueFrom:
              configMapKeyRef:
                name: region
                key: name
---
apiVersion: v1
kind: Service
metadata:
  name: hello
spec:
  type: NodePort
  ports:
  - port: 5000
    targetPort: 9898
    nodePort: 32000
  selector:
    app: hello
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: istio
  name: hello
spec:
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello
            port:
              number: 5000
EOF

cat <<EOF | kubectl --kubeconfig=karmada-config apply -f -
apiVersion: policy.karmada.io/v1alpha1
kind: PropagationPolicy
metadata:
  name: hello-propagation
spec:
  resourceSelectors:
    - apiVersion: apps/v1
      kind: Deployment
      name: hello
    - apiVersion: networking.k8s.io/v1
      kind: Ingress
      name: hello
    - apiVersion: v1
      kind: Service
      name: hello
  placement:
    clusterAffinity:
      clusterNames:
        - eu
        - sg
        - us
    replicaScheduling:
      replicaDivisionPreference: Weighted
      replicaSchedulingType: Divided
      weightPreference:
        staticWeightList:
          - targetCluster:
              clusterNames:
                - us
            weight: 1
          - targetCluster:
              clusterNames:
                - sg
            weight: 1
          - targetCluster:
              clusterNames:
                - eu
            weight: 1
EOF

# Wait for sleep to be available
# sleep 60

# REGIONS=(sg us eu)
# for REGION in "${REGIONS[@]}"; do
#   for i in {1..30}; do
#     kubectl exec --kubeconfig="kubeconfig-$REGION" -c sleep \
#       "$(kubectl get pod --kubeconfig="kubeconfig-$REGION" -l \
#         app=sleep -o jsonpath='{.items[0].metadata.name}')" \
#       -- sh -c "for i in $(seq 1 10); do wget -qO- hello:5000/env | grep REGION; done"
#   done
# done

LB_AP=$(kubectl --kubeconfig=kubeconfig-sg get service -n istio-system -l app=istio-ingressgateway -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
LB_US=$(kubectl --kubeconfig=kubeconfig-us get service -n istio-system -l app=istio-ingressgateway -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
LB_EU=$(kubectl --kubeconfig=kubeconfig-eu get service -n istio-system -l app=istio-ingressgateway -o jsonpath="{.items[0].status.loadBalancer.ingress[0].ip}")
echo "node world-map/index.js '{\"ap\":\"http://$LB_AP/env\",\"us\":\"http://$LB_US/env\",\"eu\":\"http://$LB_EU/env\"}'"
