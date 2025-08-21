#!/bin/bash

rootDir=$( dirname -- "$( readlink -f -- "$0"; )"; )

argoNamespace="argocd"



context=$(kubectl config current-context)
read -r -p "Is [${context}] the right cluster? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
  echo "Checking ${context} for existing argocd installation"
else
  echo "Aborting"
  exit 1
fi

if kubectl get namespace "$argoNamespace" &>/dev/null; then
  echo ""
  echo "Namespace '$argoNamespace' exists."
else
  echo ""
  echo "Namespace '$argoNamespace' does not exist. Creating..."
  kubectl create namespace argocd
fi


echo ""
echo "Applying ArgoCD manifests."
kubectl --namespace argocd apply --kustomize argocd


echo ""
echo "Waiting for ArgoCD to be ready."
echo ""
kubectl --namespace argocd wait --for=condition=available deployment/argocd-applicationset-controller --timeout=600s || exit 1
kubectl --namespace argocd wait --for=condition=available deployment/argocd-dex-server --timeout=600s || exit 1
kubectl --namespace argocd wait --for=condition=available deployment/argocd-notifications-controller --timeout=600s || exit 1
kubectl --namespace argocd wait --for=condition=available deployment/argocd-redis --timeout=600s || exit 1
kubectl --namespace argocd wait --for=condition=available deployment/argocd-repo-server --timeout=600s || exit 1
kubectl --namespace argocd wait --for=condition=available deployment/argocd-server --timeout=600s || exit 1

echo ""
echo "Installing root app of apps for this repo..."
echo ""
kubectl apply -f apps/k8s-test.yaml


echo ""
echo "Notes"
echo ""
echo "Initial ArgoCD Admin Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)"
