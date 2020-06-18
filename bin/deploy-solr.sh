#!/bin/bash -e

. $(dirname "$0")/shared-checks.sh
. $(dirname "$0")/efs-fun.sh
CLUSTER_NAME=$1
export CLUSTER_NAME
if check_profile && check_region && check_cluster $1 && check_params $1 && check_secrets && all_pass
then
  echo "Target cluster: ${CLUSTER_NAME}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";



  # Launch the service and register containers with the loadbalancer
  ecs-cli compose  \
    --region $AWS_DEFAULT_REGION \
    --project-name ${CLUSTER_NAME}-solr \
    --file solr-compose.yml \
    --ecs-params ${CLUSTER_NAME}-solr-params.yml \
    service up \
    $2 \
    --force-deployment \
    --create-log-groups \
    --cluster ${CLUSTER_NAME} 
fi
