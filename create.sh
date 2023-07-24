#!/usr/bin/env bash

echo "Creating k8s cluster"
kind create cluster --name stord.sre.challenge --config cluster.yaml
kubectl cluster-info --context kind-stord.sre.challenge

# kubens production
echo "Instaling Postgres Operator and UI via helm"
helm repo add stable https://charts.helm.sh/stable
helm repo add postgres-operator-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator
helm install postgres-operator postgres-operator-charts/postgres-operator
helm repo add postgres-operator-ui-charts https://opensource.zalando.com/postgres-operator/charts/postgres-operator-ui
helm install postgres-operator-ui postgres-operator-ui-charts/postgres-operator-ui

echo "Provisioning postgres cluster"
kubectl apply -f manifests/postgres.yaml
# Wait for the operator to create the needed secret to become available, the selector does not play nice with wait command
until kubectl get secret stord.challenge-database.credentials.postgresql.acid.zalan.do; do sleep 1 ;done
kubectl wait --namespace default \
  --for=condition=ready pod \
  --selector=statefulset.kubernetes.io/pod-name=challenge-database-1 \
  --timeout=90s

echo "Installing ingress-nginx"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

echo "Provisioning Application"
helm install brink ./stord-sre-challenge --set database.pass="$(kubectl get secret stord.challenge-database.credentials.postgresql.acid.zalan.do -o 'jsonpath={.data.password}' | base64 -d)"