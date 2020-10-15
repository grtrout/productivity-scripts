#!/bin/bash

# Update the project name
GCPPROJECTNAME=gcp-project-123
DEFAULT_K8S_NAMESPACE=default
K8S_NAMESPACE=${1:-$DEFAULT_K8S_NAMESPACE}
JSON_FILENAME=gcr-readonly-$GCPPROJECTNAME.json

printf "Configuring using GCP project $GCPPROJECTNAME and K8s namespace $K8S_NAMESPACE \n"

# Create JSON file with shipyard-lab svc account info
# Requires proper 'gcloud init' where this is executed

if [ -e $JSON_FILENAME ]
then
    printf "$JSON_FILENAME already exists...\n"
else
    printf "Creating key for service account...\n"
    gcloud iam service-accounts keys create --iam-account=gcr-readonly@$GCPPROJECTNAME.iam.gserviceaccount.com $JSON_FILENAME
fi

# Create docker-registry secret with the service account key
printf "Creating key for service account...\n"
kubectl -n $K8S_NAMESPACE create secret docker-registry gcr-readonly-secret \
--docker-server=https://gcr.io \
--docker-username=_json_key \
--docker-password="$(cat $JSON_FILENAME)"

printf "Patching default service account with the service account key...\n"
kubectl -n $K8S_NAMESPACE patch serviceaccount default -p '{"imagePullSecrets": [{"name": "gcr-readonly-secret"}]}'


