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
  ports:
  - port: 5000
    targetPort: 9898
  selector:
    app: hello
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sleep
spec:
  replicas: 3
  selector:
    matchLabels:
      app: sleep
  template:
    metadata:
      labels:
        app: sleep
    spec:
      terminationGracePeriodSeconds: 0
      containers:
      - name: sleep
        image: curlimages/curl
        command: ["/bin/sleep", "3650d"]
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - mountPath: /etc/sleep/tls
          name: secret-volume
      volumes:
      - name: secret-volume
        secret:
          secretName: sleep-secret
          optional: true
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
    - apiVersion: apps/v1
      kind: Deployment
      name: sleep
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
sleep 60

for i in {1..30}; do
  kubectl exec --kubeconfig=kubeconfig-us -c sleep \
    "$(kubectl get pod --kubeconfig=kubeconfig-us -l \
      app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -sS hello:5000/env | grep REGION
done

kubectl get clusters --kubeconfig=karmada-config
kubectl get pods --kubeconfig=kubeconfig-sg
kubectl get pods --kubeconfig=kubeconfig-eu
kubectl get pods --kubeconfig=kubeconfig-us
