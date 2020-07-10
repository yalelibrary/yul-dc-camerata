#!/bin/bash -e

. $(dirname "$0")/shared-checks.sh
. $(dirname "$0")/efs-fun.sh
export CLUSTER_NAME=${1}

if check_profile && check_region && check_cluster $1 && check_secrets && all_pass
then
  echo "Target cluster: ${CLUSTER_NAME}"
  echo "Using AWS_PROFILE=${AWS_PROFILE}";
  echo "      AWS_DEFAULT_REGION=${AWS_DEFAULT_REGION}";

  if [[ ! -f ${1}-solr-params.yml ]]
  then
    bin/get-params.sh ${1}
  fi

  # Launch the service and register containers with the loadbalancer
  # The $2 here can be anything, but is usually --enable-service-discovery
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
